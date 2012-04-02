#!/bin/bash

#
# Copyright (C) 2009-2012 Canonical
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

# Time to sleep during a suspend
SLEEP_SECS=30
# Time to sleep when resumed
RESUME_SECS=20
# Number of suspend resume cycles
ITERATIONS=250

loop=0
while [ $loop -lt $ITERATIONS ]
do
  loop=$((loop+1))
  if [ -e /proc/acpi/alarm ]; then
    # old style alarm interface
    DATE=`date "+%F %H:%M:%S" -d "$SLEEP_SECS sec"`
    echo $DATE > /proc/acpi/alarm
  elif [ -e /sys/class/rtc/rtc0/wakealarm ]; then
    # new style alarm interface
    SECS=`date "+%s" -d "$SLEEP_SECS sec"`
    echo $SECS > /sys/class/rtc/rtc0/wakealarm
  else
    echo "Don't know how to set alarm"
    exit 1
  fi
  echo Suspend Resume Test Cycle $loop - suspending
  pm-suspend suspend
  echo Woken up, sleeping a little before next test
  sleep $RESUME_SECS
done
