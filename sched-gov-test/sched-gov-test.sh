#!/bin/bash

#
# Copyright (C) 2016 Canonical
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

for G in $GOVS
do
	echo $G | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	for L in 10 20 30 40 50 60 70 80 90 100
	do
		echo Load: $G $L
		powerstat -R 1 60 > $G-$L.log &
		stress-ng -k -v --metrics-brief --tz --times --cpu 0 --cpu-method matrixprod --cpu-load $L --cpu-load-slice 2500 -t 60 > $G-$L-stress.log
		killall -14 stress-ng
		sleep 5
	done
	sleep 120
done
