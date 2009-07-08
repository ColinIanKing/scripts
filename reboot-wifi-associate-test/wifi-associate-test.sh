#!/bin/bash

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

LOG=/root/wifi-log.txt
#
# Time to give up with associating
#
TIMEOUT=300
#
# Set the Access Point IP address with AP
#
AP=192.168.1.1
count=0
start=`date "+%s"`
while true
do
	ping -c 3 $AP  >& /dev/null
	ret=$?
	now=`date "+%s"`
	running=`expr $now - $start`
	if [ $ret -eq 0 ]
	then
		echo "Associated after $running seconds at `date`" >> $LOG
		break
	else		
		count=$((count + 1))
		if [ $running -gt $TIMEOUT ]
		then
			echo "Failed to associate after $running seconds at `date` ($count tries)" >> $LOG
			break
		fi
	fi
done
sleep 5
reboot
exit 0
