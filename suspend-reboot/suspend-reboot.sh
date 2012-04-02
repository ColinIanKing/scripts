#!/bin/sh

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

#
# Execute this from /etc/rc.local
#
# This script will soak test 200 suspend, reboot cycles
#
sleep 60
if [ -e /root/count ]
then
	n=`cat /root/count`
else
	n=0
fi
n=$((n+1))
if [ $n -le 200 ]
then
	echo SLEEP $n
	pm-suspend
	echo REBOOT $n
	echo $n > /root/count
	sync
	reboot
fi
