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

if [ x`whoami` != "xroot" ]; then
  echo "Need to run with sudo!"
  exit 1
fi
if [ ! -e /sys/class/rtc/rtc0/wakealarm ]; then
  echo "Your don't seem to have the /sys/class/rtc/rtc0/wakealarm interface"
  exit 1
fi
#
# Author Colin Ian King,  colin.king@canonical.com
#
SLEEP_SECS=5
SLEEP_MAX=70
SLEEP_DELTA=20

diff=$((`date '+%s'`-`cat /sys/class/rtc/rtc0/since_epoch`))
echo "There are $diff seconds difference between date and epoch"

while [ $SLEEP_SECS -lt $SLEEP_MAX ]
do
  echo "ACPI alarm test: alarm in $SLEEP_SECS seconds time: "
  SECS=$((`cat /sys/class/rtc/rtc0/since_epoch`+$SLEEP_SECS))
  echo 0 > /sys/class/rtc/rtc0/wakealarm
  echo $SECS > /sys/class/rtc/rtc0/wakealarm
#
# Test 1 - test if the alarm is triggered and ready to fire
#
  alarmset=`cat /proc/driver/rtc | grep alarm_IRQ | awk '{ print $3 }'`
  if [ x$alarmset != 'xyes' ]; then
    echo "  FAILED: Cannot set ACPI alarm!"
    exit 1
  else
    echo "  PASSED: Can set ACPI alarm"
  fi

  echo -n "  SLEEP: "
  secs=0
  while [ $secs -lt $SLEEP_SECS ]
  do
    echo -n "."
    secs=$((secs+1))
    sleep 1
  done
#
# and one more just in case!
#
  sleep 1
  echo ""
#
# Test 2 - test if the alarm has fired
#
  alarmset=`cat /proc/driver/rtc | grep alarm_IRQ | awk '{ print $3 }'`
  if [ x$alarmset != 'xno' ]; then
    echo "  FAILED: ACPI alarm has not triggered!"
    exit 1
  else
    echo "  PASSED: ACPI alarm was triggered"
  fi
  echo " "
  SLEEP_SECS=$((SLEEP_SECS+$SLEEP_DELTA))
done

#
# Finished!
#
echo "ACPI alarm PASSED all the tests"
exit 0
