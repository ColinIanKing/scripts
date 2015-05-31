#!/bin/bash
#
# Copyright (C) 2015 Canonical
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

#!/bin/bash

for I in /sys/class/powercap/*
do
	if [ -e $I/name ]; then
		name=$(cat $I/name)
		if [ "x$name" == "xuncore" ]; then
			uncore=$I/energy_uj
		fi
	fi
done

DRI_PATH=/sys/kernel/debug/dri/0
i915_uj_prev=$(cat $DRI_PATH/i915_energy_uJ)
uncore_uj_prev=$(cat $uncore)
delta=1
printf "%8s %12s %12s %12s\n" "Time" "i915 (mW)" "uncore (mW)" "GPU Freq"
while true
do
	sleep $delta

	uncore_uj=$(cat $uncore)
	i915_uj=$(cat $DRI_PATH/i915_energy_uJ)
	frq=$(cat $DRI_PATH/i915_frequency_info | grep RPNSWREQ | awk '{ print $2}')

	i915_uj_delta=$((i915_uj - $i915_uj_prev))
	i915_uj_prev=$i915_uj

	uncore_uj_delta=$((uncore_uj - $uncore_uj_prev))
	uncore_uj_prev=$uncore_uj

	i915_milliWatts=$(echo "scale=3; $i915_uj_delta/(1000 * $delta)" | bc)
	uncore_milliWatts=$(echo "scale=3; $uncore_uj_delta/(1000 * $delta)" | bc)
	printf "%8s %12s %12s %12s\n" $(date '+%X') $i915_milliWatts $uncore_milliWatts $frq
done
