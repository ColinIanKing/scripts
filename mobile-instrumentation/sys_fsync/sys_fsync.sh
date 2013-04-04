#!/bin/bash 

#
# Copyright (C) 2013 Canonical
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
# This script measures the processes that are calling sys_fsync. The output
# is a table of the frequency of sys_fsync calls, process id and process name
# sorted in highest sys_fsync caller order.
#
# Usage:
#	sys_fsync [ duration ] [ count ]
#
# defaults to 1 iteration of 60 seconds of sampling time.
#

DEBUGFS_PATH=/sys/kernel/debug
DEBUGFS_UMOUNT=0

PROCFS_PATH=/proc
PROCFS_UMOUNT=0

SAMPLES=1
INTERVAL=60

if [ $UID -ne 0 ]; then
	echo "Need to be root to run this command"
	exit 1
fi

if [ $# -gt 0 ]; then
	INTERVAL=$1
fi
if [ $# -gt 1 ]; then
	SAMPLES=$2
fi

#
#  Require debugfs mounted
#
debugfs_mount()
{
	mnt=$(cat /proc/mounts | grep debugfs | head -1)

	if [ -z "$mnt" ]; then
		mount -t debugfs none ${DEBUGFS_PATH}
		if [ $? -ne 0 ]; then
			echo "Failed to mount ${DEBUGFS_PATH}"
			exit 1
		fi
		DEBUGFS_UMOUNT=1
	else
		DEBUGFS_PATH=$(echo $mnt | cut -d' ' -f2)
	fi
}

debugfs_umount()
{
	if [ ${DEBUGFS_UMOUNT} -eq 1 ]; then
		umount ${DEBUGFS_PATH}
	fi
}

#
#  Require /proc mounted
#
procfs_mount()
{
	mnt=$(cat /proc/mounts | grep proc | head -1)

	if [ -z "$mnt" ]; then
		mount -t proc none ${PROCFS_PATH}
		if [ $? -ne 0 ]; then
			echo "Failed to mount ${PROCFS_PATH}"
			exit 1
		fi
		PROCFS_UMOUNT=1
	else
		PROCFS_PATH=$(echo $mnt | cut -d' ' -f2)
	fi
}

procfs_umount()
{
	if [ ${PROCFS_UMOUNT} -eq 1 ]; then
		umount ${PROCFS_PATH}
	fi
}

tidy_error()
{
	echo $1
	procfs_umount
	debugfs_umount
	exit 1
}

trace_on()
{
	if [ ! -e /proc/sys/kernel/ftrace_enabled ]; then
		tidy_error "Cannot enable tracing, no such file /proc/sys/kernel/ftrace_enabled"
	fi

	echo 1 > /proc/sys/kernel/ftrace_enabled
	if [ $? -ne 0 ]; then
		tidy_error "Cannot enable tracing"
	fi

	echo "function" > ${DEBUGFS_PATH}/tracing/current_tracer
	if [ $? -ne 0 ]; then
		tidy_error "Cannot enable function tracing"
	fi

	echo "sys_fsync" > ${DEBUGFS_PATH}/tracing/set_ftrace_filter
	if [ $? -ne 0 ]; then
		tidy_error "Cannot trace sys_fsync"
	fi

	echo 1 > ${DEBUGFS_PATH}/tracing/tracing_on
	if [ $? -ne 0 ]; then
		tidy_error "Cannot turn on tracing"
	fi

	echo "" > trace

}

trace_off()
{
	echo "" > ${DEBUGFS_PATH}/tracing/set_ftrace_filter
	echo 0 > ${DEBUGFS_PATH}/tracing/tracing_on
	echo "nop" > ${DEBUGFS_PATH}/tracing/current_tracer
	echo 0 > /proc/sys/kernel/ftrace_enabled
}

trace_parse()
{
	echo "Count  Pid  Process"
	cat ${DEBUGFS_PATH}/tracing/trace | grep -v "^#" | cut -c1-23 | while read proc
	do
		pid=${proc##*-}
		tsk=${proc%%-*}
		echo "$pid $tsk"
	done | awk '
{
	pid[$1]++
	proc[$1]=$2
} 
END {
	for (i in pid)
		printf "%5d %5d %s\n", pid[i], i, proc[i]
}' | sort -r -n

	echo "" > ${DEBUGFS_PATH}/tracing/trace
}

time_get()
{
	date "+%s.%N"
}

time_delta()
{
	echo "$1 + $2 - $3" | bc
}

debugfs_mount
procfs_mount

trace_on

time_start=$(time_get)
s=0
t=0
while [ $s -lt ${SAMPLES} ]; 
do
	s=$((s + 1))
	t=$((t + ${INTERVAL}))
	time_here=$(time_get)
	time_wait=$(time_delta $t $time_start $time_here)

	sleep $time_wait

	trace_parse
done

trace_off

procfs_umount
debugfs_umount
