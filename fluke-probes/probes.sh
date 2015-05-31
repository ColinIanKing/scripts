#!/bin/bash

PROBE_TMP=/tmp
GPUSTAT_LOG=$PROBE_TMP/gpustat.log
CPUSTAT_CSV=$PROBE_TMP/cpustat.csv
CPUSTAT_LOG=$PROBE_TMP/cpustat.log
EVENTSTAT_CSV=$PROBE_TMP/eventstat.csv
EVENTSTAT_LOG=$PROBE_TMP/eventstat.log
FATRACE_LOG=$PROBE_TMP/fatrace.log
SUSPEND_BLOCKER_LOG=$PROBE_TMP/suspend-blocker.log

probes_log_dump()
{
	if [ -e $1 ]; then
		cat $1
	else
		echo "Can't find log file $1"
	fi
}

probes_setup()
{
	echo "lib/probes: probes_setup"
	#
	#  PPA for new probe tools
	#
	if [ ! -d /etc/apt/sources.list.d/colin-king-white-saucy.list ]; then
		add-apt-repository -y ppa:colin-king/white
		apt-get update
	fi
	#
	#  Monitors
	#
	which eventstat || apt-get install -yq --force-yes eventstat
	which cpustat || apt-get install -yq --force-yes cpustat
	which nexus4-gpustat || apt-get install -yq --force-yes nexus4-gpustat
	which fatrace || apt-get install -yq --force-yes fatrace
	which suspend-blocker || apt-get install -yq --force-yes suspend-blocker
	#
	#  Misc tools
	#
	which bc || apt-get install -yq --force-yes bc
	#
	#  For Monitoring purposes...
	#
	grep "proc /proc" /proc/mounts || mount -t proc proc /proc
}

probes_cleanup()
{
	echo "lib/probes: probes_cleanup"
}

#
#  FLUKE probe
#
probe_fluke_tagmsg()
{
        echo "$*" | nc -u -q 1 192.168.0.3 3500 &
}

probe_fluke_prepare_begin()
{
	probe_fluke_tagmsg TEST_CLIENT phone
	sleep 1
	probe_fluke_tagmsg TEST_BEGIN $TEST
	sleep 1
}

probe_fluke_prepare_end()
{
	sleep 1
	probe_fluke_tagmsg TEST_END $TEST
}

probe_fluke_begin()
{
	probe_fluke_tagmsg TEST_RUN_BEGIN $TEST
}

probe_fluke_stop()
{
	probe_fluke_tagmsg TEST_RUN_END $TEST
}

probe_fluke_report()
{
	sleep 1
	probe_fluke_tagmsg TEST_REPORT $TEST
	echo "FLUKE: no-op"
}

#
#  interrupts
#
probe_interrupts_begin()
{
	intr_start=$(grep "intr" /proc/stat  | cut -d' ' -f2)
	intr_start_sec=$(date +%s)
}

probe_interrupts_stop()
{
	intr_end=$(grep "intr" /proc/stat  | cut -d' ' -f2)
	intr_end_sec=$(date +%s)
}

probe_interrupts_report()
{
	intr_secs=$(echo "$intr_end_sec - $intr_start_sec" | bc)
	intr_delta=$(echo "$intr_end - $intr_start" | bc)
	intr_rate=$(echo "scale=4; $intr_delta / $intr_secs" | bc)
	echo "**** INTERRUPTS ****"
	echo ""
	echo "Interrupts : $intr_start $intr_end $intr_delta"
	echo "Test Duration: " $intr_secs " seconds "
	echo "Interrupt Rate (per second): $intr_rate"
	echo ""
}

#
#  GPU stat
#
probe_gpustat_begin()
{
	rm -rf $LOG
	gpustat_pid=0
	case `uname -r` in
	*mako*)
		sudo mount -t debugfs none /sys/kernel/debug
		sudo nexus4-gpustat -q -t $GPUSTAT_LOG 1 $DURATION &
		gpustat_pid=$!
		;;
	*)
		echo Unknown device
		;;
	esac
}

probe_gpustat_stop()
{
	if [ $gpustat_pid -ne 0 ]; then
		sudo kill -SIGINT $gpustat_pid >& /dev/null
	fi
}

probe_gpustat_report()
{
	echo "**** GPU USAGE ****"
	echo ""
	if [ $gpustat_pid -ne 0 ]; then
		wait $gpustat_pid
		sudo umount /sys/kernel/debug
		echo " "
		echo "GPU activity:"
		probes_log_dump $GPUSTAT_LOG
		echo ""
		sudo rm -rf $GPUSTAT_LOG
	else
		echo "NO DATA FOR THIS MACHINE"
	fi
}

#
#  Eventstat
#
probe_eventstat_begin()
{
	sudo rm -f $EVENTSTAT_LOG
	sudo eventstat -r $EVENTSTAT_CSV -l -c -d $DURATION > $EVENTSTAT_LOG &
	eventstat_pid=$!
}

probe_eventstat_stop()
{
	sudo kill -SIGINT $eventstat_pid >& /dev/null
}

probe_eventstat_report()
{
	wait $eventstat_pid
	echo ""
	echo "**** EVENTSTAT CSV START ****"
        probes_log_dump $EVENTSTAT_CSV
        echo "**** EVENTSTAT CSV END ****"
	echo 
	echo "**** EVENTSTAT LOG START ****"
        probes_log_dump $EVENTSTAT_LOG
        echo "**** EVENTSTAT LOG END ****"
        echo ""
	sudo rm -f $EVENTSTAT_LOG
}


#
#  cpustat
#
probe_cpustat_begin()
{
	sudo rm -rf $CPUSTAT_LOG $CPUSTAT_CSV
        sudo cpustat -r $CPUSTAT_CSV $DURATION > $CPUSTAT_LOG &
        cpustat_pid=$!
	echo "CPUSTAT PID: $cpustat_pid"
}

probe_cpustat_stop()
{
        sudo kill -SIGINT $cpustat_pid >& /dev/null
}

probe_cpustat_report()
{
	wait $cpustat_pid
        echo "**** CPU USAGE ****"
        echo ""

        echo " "
        echo "CPU top processes:"
        probes_log_dump $CPUSTAT_LOG
        echo " "
        echo "CPU csv data:"
        probes_log_dump $CPUSTAT_CSV
        echo ""
        sudo rm -rf $LOG $CSV
}

#
#  fatrace probe
#
probe_fatrace_begin()
{
	sudo rm -f $FATRACE_LOG
	tmp_pwd=$(pwd)
	cd /
	sudo fatrace -c -t -s $DURATION > $FATRACE_LOG &
	fatrace_pid=$!
	cd $tmp_pwd
	echo "FATRACE PID: $fatrace_pid"
}

probe_fatrace_stop()
{
        sudo kill -SIGHUP $fatrace_pid >& /dev/null
        sudo kill -SIGINT $fatrace_pid >& /dev/null
}

probe_fatrace_report()
{
	wait $pid

	echo "**** FILE ACTIVITY ****"
	echo ""
	cat $FATRACE_LOG | awk '
{
        if (index($3, "O"))
                hist[$2 " open " ]++
        if (index($3, "C"))
                hist[$2 " close " ]++
        if (index($3, "R"))
                hist[$2 " read " ]++
        if (index($3, "W"))
                hist[$2 " write " ]++
}
END {
        for (i in hist)
                printf "%7d %s\n", hist[i], i
}
' | sort -n -r
	echo ""

	rm -f $FATRACE_LOG
}

#
#  Context switches
#
probe_context_switch_begin()
{
	ctxt_start=$(grep "ctxt" /proc/stat  | cut -d' ' -f2)
	ctxt_start_secs=$(date +%s)
}

probe_context_switch_stop()
{
	ctxt_end=$(grep "ctxt" /proc/stat  | cut -d' ' -f2)
	ctxt_end_secs=$(date +%s)
}

probe_context_switch_report()
{
	ctxt_secs=$(echo "$ctxt_end_secs - $ctxt_start_secs" | bc)
	ctxt_delta=$(echo "$ctxt_end - $ctxt_start" | bc)
	ctxt_rate=$(echo "scale=4; $ctxt_delta / $ctxt_secs" | bc)
	echo "**** CONTEXT SWITCHES ****"
	echo ""
	echo "Context Switches : $ctxt_start $ctxt_end $ctxt_delta"
	echo "Test Duration: " $ctxt_secs " seconds "
	echo "Context Switch Rate (per second): $ctxt_rate"
	echo ""
}

#
#  Suspend-blockers. This is a hack for now, need
#  to look at the kernel log in a better way than this.
#
probe_suspend_blockers_begin()
{
	rm -rf $SUSPEND_BLOCKER_LOG
	sudo dmesg -c > /dev/null
}

probe_suspend_blockers_stop()
{
	sudo dmesg > $SUSPEND_BLOCKER_LOG
}

probe_suspend_blockers_report()
{
	echo "**** SUSPEND BLOCKERS ****"
	echo ""
	cat $SUSPEND_BLOCKER_LOG | suspend-blocker
	echo ""
	rm -rf $SUSPEND_BLOCKER_LOG
}



#probes_setup

sudo chmod 777 /dev/uinput

do_test()
{
	DURATION=5000
	TEST="surface flinging"

	probe_fluke_prepare_begin

	autopilot run switch-to-and-fro_tests &
	ap_pid=$!
	sleep 15

	probe_interrupts_begin
	probe_context_switch_begin
	probe_suspend_blockers_begin
	probe_fluke_begin
	probe_fatrace_begin

	sleep 300

	probe_fatrace_stop
	probe_interrupts_stop
	probe_context_switch_stop
	probe_suspend_blockers_stop
	probe_fluke_stop

	probe_interrupts_report
	probe_context_switch_report
	probe_fatrace_report
	probe_suspend_blockers_report
	probe_fluke_report

	probe_fluke_prepare_end

	sleep 10

	kill -SIGHUP $ap_pid
	wait $ap_pid
}

echo TEST 
do_test
echo DONE

probe_fluke_tagmsg TEST_QUIT

