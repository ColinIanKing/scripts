#!/bin/bash  -x

#
# Copyright (C) 2009 Canonical
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

#
# Author Colin Ian King,  colin.king@canonical.com
#

duration=60

setup_wakeup_timer ()
{
	timeout="$1"

	#
	# Request wakeup from the RTC or ACPI alarm timers.  Set the timeout
	# at 'now' + $timeout seconds.
	#
	ctl='/sys/class/rtc/rtc0/wakealarm'
	if [ -f "$ctl" ]; then
		time=`date '+%s' -d "+ $timeout seconds"`
		# Cancel any outstanding timers.
		echo "0" >"$ctl"
		# rtcN/wakealarm uses absolute time in seconds
		echo "$time" >"$ctl"
		return 0
	fi
	ctl='/proc/acpi/alarm'
	if [ -f "$ctl" ]; then
		echo `date '+%F %H:%M:%S' -d '+ '$timeout' seconds'` >"$ctl"
		return 0
	fi

	echo "no method to awaken machine automatically" 1>&2
	exit 1
}

get_time_now()
{
	date +%s
}

get_capacity()
{
	cat /proc/acpi/battery/*/state | grep 'remaining capacity'  | awk 'BEGIN { cap=0 } {cap=cap+$3 } END { print cap }' 
}

get_capacity_units()
{
	cat /proc/acpi/battery/*/state | grep 'remaining capacity'  | awk '{ print $4 }' 
}

quick_hibernate_power_check()
{
	cap_before=`get_capacity`
	setup_wakeup_timer 60
	pm-hibernate
	cap_after=`get_capacity`
	power_hibernate=`expr $cap_before - $cap_after`
	echo $power_hibernate 
}

timed_hibernate_power_check()
{
	setup_wakeup_timer $2
	cap_before=`get_capacity`
	sec_before=`get_time_now`
	pm-hibernate
	cap_after=`get_capacity`
	sec_after=`get_time_now`
	sec_taken=`expr $sec_after - $sec_before`
	power_hibernate=`expr $cap_before - $cap_after`
	power_hibernate=`expr $power_hibernate - $1`
	power_hibernate=`expr $sec_taken \* $power_hibernate`
	power_hibernate=`expr $power_hibernate / 3600`
	echo $power_hibernate
}


while :
do
	case "$1" in
	--modules)	
		modules_file=$2
		shift 2
		;;
	--duration)
		duration=$2
		shift 2
		;;
	*)	shift
		break
		;;
	esac
done



units=`get_capacity_units`

echo Please wait - checking power consumption of hibernate
hibernate_power=`quick_hibernate_power_check`
if [ $hibernate_power -lt 0 ]
then
	echo Strange, the battery is gaining charge.
	echo Are you sure the machine is not being charged?
else
	echo Hibernation action $hibernate_power $units
fi

if [ x$modules_file != x ]
then
	echo Processing modues lised in  $modules_file
	before=`timed_hibernate_power_check $hibernate_power $duration`
	for F in `cat $module_file`
	do
		echo Power before $F $before $units
		modprobe $F
		after =`timed_hibernate_power_check $hibernate_power $duration`
		echo Power after loading $F $after
		before=$after
	done
fi

exit

echo Please wait - checking power consumption of long hibernate - $duration seconds
power=`timed_hibernate_power_check $hibernate_power $duration`
echo Hibernation consumes $power $units

exit 0
