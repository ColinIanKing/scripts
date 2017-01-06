#!/bin/bash

#
# Copyright (C) 2017 Canonical
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

GOVS=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors)
GOVS="performance powersave"

U=$(uname -r)
D=60

for G in $GOVS
do
	echo $G | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	for L in 10 20 30 40 50 60 70 80 90 100
	do
		echo Load: $G $L $U
		powerstat -R 1 $D > $G-$L-$U.log &
		./stress-ng/stress-ng -k -v --metrics-brief --tz --times --cpu 0 --cpu-method matrixprod --cpu-load $L --cpu-load-slice 2500 -t $D > $G-$L-$U-stress.log
		killall -14 stress-ng
		sleep 1
	done
	sleep 30
done
