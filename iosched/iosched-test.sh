#!/bin/bash
#
# Copyright (C) 2012 Canonical
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

TEST_DRIVE=sdb
TEST_DEV=/dev/${TEST_DRIVE}
TEST_FS=ext4
TEST_MOUNT=/tmp/mnt
TEST_MKFS_FORCE=-F
TEST_ITERATIONS=3
TEST_TMP=/tmp
TEST_GRAPH_PATH=graphs/$(date "+%d-%m-%Y")/$(uname -r)-$(uname -m)
TEST_DD_COUNT=1
TEST_BONNIE_ARGS="-q -r 2048 -s 4096 -u0:0 -d ${TEST_MOUNT}"

test_mkfs()
{	
	mkfs $TEST_MKFS_FORCE -t $TEST_FS $TEST_DEV >& /dev/null
	return $?
}

test_mount()
{
	mkdir -p $TEST_MOUNT
	mount -t $TEST_FS $TEST_DEV $TEST_MOUNT
	return $?
}

test_umount()
{
	sleep 2
	umount $TEST_MOUNT
	return $?
}

test_bonnie_latency()
{
	v=$(echo $1 | awk '{print $1 + 0}')
	case $1 in
	*ms)
		echo $v
		;;
	*us)
		echo $(echo $1 | awk '{print $1 / 1000}')
		;;
	*s)
		echo $((v * 1000))
		;;
	esac
}

test_bonnie_get_sample()
{
	blk_wr_rate=$(echo $1 | cut -d',' -f 10)
	blk_rw_rate=$(echo $1 | cut -d',' -f 12)
	blk_rd_rate=$(echo $1 | cut -d',' -f 14)

	blk_wr_latency=$(test_bonnie_latency $(echo $1 | cut -d',' -f 38))
	blk_rw_latency=$(test_bonnie_latency $(echo $1 | cut -d',' -f 39))
	blk_rd_latency=$(test_bonnie_latency $(echo $1 | cut -d',' -f 40))

	echo $blk_wr_rate $blk_rw_rate $blk_rd_rate $blk_wr_latency $blk_rw_latency $blk_rd_latency
}	

test_bonnie()
{
	test_bonnie_get_sample $(bonnie++ ${TEST_BONNIE_ARGS} 2>&-)
}


test_dd()
{
	dd if=/dev/zero of=$TEST_MOUNT/test.dat bs=1M count=$TEST_DD_COUNT 2>&1 | tail -1 | cut -d' ' -f8
	rm -rf $TEST_MOUNT/test.dat >& /dev/null
}

#
#  Data format for errorbar graph:
#	x y ylo yhi
#
#  where x: values to iterate over, y: value
#
test_graph_generic()
{
	local col1=$6
	local col2=$7
	local col3=$(($7+1))
	local col4=$(($7+2))

	local data=$5
	local graph=${TEST_GRAPH_PATH}/${4}-graph.jpg

cat <<EOF_HERE > $TEST_TMP/iosched.gnu
set style fill solid 1.00 border -1
set title "$1"
set xlabel "$2"
set ylabel "$3"
set terminal jpeg medium
plot "${data}" using ${col1}:${col2}:${col3}:${col4} with errorbars title "Min/Max", \
     "${data}" using ${col1}:${col2} with lines title "Average"
EOF_HERE
gnuplot $TEST_TMP/iosched.gnu > ${graph}

}

test_graph_single()
{
	local title="$1"
	local xlabel="$2"
	local ylabel="$3"
	local graph="$4"
	local data="$5"

	test_graph_generic "${title}" "$xlabel" "$ylabel" "${graph}" "$data" 1 2
}


test_graph_bonnie()
{
	local prefix="$1"
	local title="$2"
	local xlabel="$3"
	local ylabel="$4"
	local graph="$5"
	local data="$6"

	test_graph_generic "${title}, ${TEST_FS}, Sequential Block Writes" "$xlabel" "Writes, K/sec" "${prefix}-seq-write-${graph}" "$data" 1 2
	test_graph_generic "${title}, ${TEST_FS}, Sequential Block Re-Writes" "$xlabel" "Re-Writes, K/sec" "${prefix}-seq-rewrite-${graph}" "$data" 1 5
	test_graph_generic "${title}, ${TEST_FS}, Sequential Block Reads" "$xlabel" "Reads, K/sec" "${prefix}-seq-read-${graph}" "$data" 1 8

	test_graph_generic "${title}, ${TEST_FS}, Sequential Block Write Latency" "$xlabel" "Write latency (ms)" "${prefix}-seq-write-latency-${graph}" "$data" 1 11
	test_graph_generic "${title}, ${TEST_FS}, Sequential Block Re-Write Latency" "$xlabel" "Re-Write latency (ms)" "${prefix}-seq-rewrite-latency-${graph}" "$data" 1 14
	test_graph_generic "${title}, ${TEST_FS}, Sequential Block Read Latency" "$xlabel" "Read latency (ms)" "${prefix}-seq-read-latency-${graph}" "$data" 1 17
}

inform()
{
	echo $@ 1>&2
}



test_average()
{
        awk '
BEGIN { n=0; nfields=0 }
{       
        n=n+1;
	for (i=1;i<=NF;i++) {
		total[i]+=$i;
        	if (n==1) { min[i]=$i; max[i]=$i };
        	if ($1 > max[i]) max[i] = $i;
        	if ($1 < min[i]) min[i] = $i;
	}
	if (nfields<NF) nfields=NF
}
END {  for (i=1;i<=nfields;i++)
		printf "%f %f %f ",total[i] / n, min[i], max[i] 
	printf "\n"
}
'
}

test_run_iterate()
{
	prefix=$1
	iter=$2
	title=$3
	xaxis=$4
	yaxis=$5
	test_func=$6
	tweak_func=$7
	shift 7

	mkdir -p ${TEST_GRAPH_PATH}
	TEST_DATA_PATH=${TEST_GRAPH_PATH}/data
	mkdir -p ${TEST_DATA_PATH}

	data=${TEST_DATA_PATH}/${prefix}-${iter}-graph.txt

	for tweak in $@
	do
		samples=${TEST_DATA_PATH}/${prefix}-${iter}-${tweak}-samples.txt
		$tweak_func $tweak
		echo -n "$tweak "
	if [ 0 -eq 0 ]; then
		for i in $(seq $TEST_ITERATIONS)
		do
			inform "iteration $i of ${TEST_ITERATIONS}"
			test_mkfs > /dev/null
			test_mount > /dev/null
			$test_func
			test_umount > /dev/null
		done > $samples
	fi
		cat $samples | test_average
	done > ${data}

	#test_graph_single "$title" "$xaxis" "$yaxis" "${iter}" "${data}"
	test_graph_bonnie "$prefix" "$title" "$xaxis" "$yaxis" "${iter}" "${data}"
}

test_run()
{
	prefix="$1"
	tweakables=($2)
	tweakables_xlabels=($3)
	tweakables_graphname=($4)
	title="$5"
	yaxis="$6"
	test_func="$7"
	shift 7

	for i in ${!tweakables[*]}
	do
		xaxis="${tweakables_xlabels[$i]}"
		tweak_func="${tweakables[$i]}"
		graph_name="${tweakables_graphname[$i]}"
		echo "Test: ${test_func}, Setting func: $tweak_func x-axis label: $xaxis graph prefix: $graph_name"
		test_run_iterate "$prefix" "$graph_name" "$title" "$xaxis" "$yaxis" "$test_func" "$tweak_func" $@
	done

}

sched_cfq()
{
	echo cfq > /sys/block/${TEST_DRIVE}/queue/scheduler
	#
	#  Defaults
	#
	echo "248" > /sys/block/${TEST_DRIVE}/queue/iosched/fifo_expire_async
	echo "128" > /sys/block/${TEST_DRIVE}/queue/iosched/fifo_expire_sync
	echo "100" > /sys/block/${TEST_DRIVE}/queue/iosched/slice_sync
	echo "40" > /sys/block/${TEST_DRIVE}/queue/iosched/slice_async
	echo "2" > /sys/block/${TEST_DRIVE}/queue/iosched/slice_async_rq
	echo "8" > /sys/block/${TEST_DRIVE}/queue/iosched/slice_idle
	echo "8" > /sys/block/${TEST_DRIVE}/queue/iosched/quantum
}

sched_deadline()
{
	echo deadline > /sys/block/${TEST_DRIVE}/queue/scheduler
	#
	#  Defaults
	#
	echo "16" > /sys/block/${TEST_DRIVE}/queue/iosched/fifo_batch
	echo "1" > /sys/block/${TEST_DRIVE}/queue/iosched/front_merges
	echo "500" > /sys/block/${TEST_DRIVE}/queue/iosched/read_expire
	echo "5000" > /sys/block/${TEST_DRIVE}/queue/iosched/write_expire
	echo "2" > /sys/block/${TEST_DRIVE}/queue/iosched/writes_starved
}

sched_noop()
{
	echo noop > /sys/block/${TEST_DRIVE}/queue/scheduler
	#
	# no defaults
	#
}

sched_tweak_cfq_fifo_expire_async()
{
	sched_cfq
	file=/sys/block/${TEST_DRIVE}/queue/iosched/fifo_expire_async
	inform "cfq_fifo_expire_async, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_cfq_fifo_expire_sync()
{
	sched_cfq
	file=/sys/block/${TEST_DRIVE}/queue/iosched/fifo_expire_sync
	inform "cfq_fifo_expire_sync, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_cfq_slice_sync()
{
	sched_cfq
	file=/sys/block/${TEST_DRIVE}/queue/iosched/slice_sync
	inform "cfq_slice_sync, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_cfq_slice_async()
{
	sched_cfq
	file=/sys/block/${TEST_DRIVE}/queue/iosched/slice_async
	inform "cfq_slice_async, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_cfq_slice_async_rq()
{
	sched_cfq
	file=/sys/block/${TEST_DRIVE}/queue/iosched/slice_async_rq
	inform "cfq_slice_async_rq, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_cfq_slice_idle()
{
	sched_cfq
	file=/sys/block/${TEST_DRIVE}/queue/iosched/slice_idle
	inform "cfq_slice_idle, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_cfq_quantum()
{
	sched_cfq
	file=/sys/block/${TEST_DRIVE}/queue/iosched/quantum
	inform "cfq_quantum, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_deadline_read_expire()
{
	sched_deadline
	file=/sys/block/${TEST_DRIVE}/queue/iosched/read_expire
	inform "deadline_read_expire, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_deadline_write_expire()
{
	sched_deadline
	file=/sys/block/${TEST_DRIVE}/queue/iosched/write_expire
	inform "deadline_write_expire, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_deadline_fifo_batch()
{
	sched_deadline
	file=/sys/block/${TEST_DRIVE}/queue/iosched/fifo_batch
	inform "deadline_fifo_batch, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_deadline_writes_starved()
{
	sched_deadline
	file=/sys/block/${TEST_DRIVE}/queue/iosched/writes_starved
	inform "deadline_writes_starved, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_deadline_front_merges()
{
	sched_deadline
	file=/sys/block/${TEST_DRIVE}/queue/iosched/front_merges
	inform "deadline_front_merges, setting $file to $1"
	echo "$1" > $file
}

sched_tweak_noop()
{
	sched_noop
	inform "noop, test iteration $1"
}


#
# CFQ tests
#
test_run "CFQ" "sched_tweak_cfq_fifo_expire_async sched_tweak_cfq_fifo_expire_sync" "CFQ:fifo_expire_async CFQ:fifo_expire_sync" "fifo_expire_async fifo_expire_sync" "Bonnie++, CFQ" "" test_bonnie $(seq 50 50 500)

test_run "CFQ" "sched_tweak_cfq_slice_async sched_tweak_cfq_slice_sync" "CFQ:slice_async CFQ:slice_sync" "slice_async slice_sync" "Bonnie++, CFQ" "" test_bonnie $(seq 10 20 150)

test_run "CFQ" "sched_tweak_cfq_slice_async_rq" "CFQ:slice_async_rq" "slice_async_rq" "Bonnie++, CFQ " "" test_bonnie $(seq 1 1 10)

test_run "CFQ" "sched_tweak_cfq_slice_idle" "CFQ:slice_idle" "slice_idle" "Bonnie++, CFQ" "" test_bonnie $(seq 2 2 32)
#
test_run "CFQ" "sched_tweak_cfq_quantum" "CFQ:quantum" "quantum" "Bonnie++, CFQ" "" test_bonnie $(seq 1 2 32)


#
# Deadline tests
#
test_run "Deadline" "sched_tweak_deadline_read_expire" "deadline:read_expire" "read_expire" "Bonnie++, deadline" "" test_bonnie $(seq 100 100 1000)

test_run "Deadline" "sched_tweak_deadline_write_expire" "deadline:write_expire" "write_expire" "Bonnie++, deadline" "" test_bonnie $(seq 100 100 1000)

test_run "Deadline" "sched_tweak_deadline_fifo_batch" "deadline:fifo_batch" "fifo_batch" "Bonnie++, deadline" "" test_bonnie $(seq 1 2 64)

test_run "Deadline" "sched_tweak_deadline_writes_starved" "deadline:writes_starved" "writes_starved" "Bonnie++, deadline" "" test_bonnie $(seq 1 1 16)

test_run "Deadline" "sched_tweak_deadline_front_merges" "deadline:front_merges" "front_merges" "Bonnie++, deadline" "" test_bonnie $(seq 0 1 1)

#
# No-op tests
#
test_run "Noop" "sched_tweak_noop" "noop:multiple-tests" "test" "Bonnie++, noop" "" test_bonnie $(seq 1 1 5)
