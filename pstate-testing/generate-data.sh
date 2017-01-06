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

SEP=","

show_kerns()
{
	echo -ne "Load"
	for k in $kerns
	do
		echo -ne "$SEP$k"
	done
	echo
}

#loads="10 20 30 40 50 60 70 80 90 100"
loads="5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100"

#kerns=$(cat kerns)
kerns="3.2.0-119 3.5.0-51 3.8.0-35 3.11.0-26 3.13.0-106 3.16.0-44 3.19.0-78 4.2.0-42 4.4.0-58 4.8.0-32 4.9.0-12"

kernsgen=""
for k in $kerns
do
	kernsgen="$kernsgen $k-generic"
done
kerns=$kernsgen

kerns="4.4.0 4.5.0 4.6.0 4.7.0 4.8.0 4.9.0"

for p in performance powersave
do
	echo 
	echo $p
	echo 

	echo "CPU power (Watts)"
	show_kerns
	for l in $loads
	do
		echo -n "$l"
		for k in $kerns
		do
			w=$(grep Average $p-$l-$k.log | awk '{print $NF }')
			echo -n "$SEP$w"
		done
		echo ""
	done
	echo ""

	echo "Bogo Ops/sec"
	show_kerns
	for l in $loads
	do
		echo -n "$l"
		for k in $kerns
		do
			b=$(grep "cpu " $p-$l-$k-stress.log | awk '{print $(NF-1)}')
			echo -n "$SEP$b"
		done
		echo ""
	done
	echo ""

	echo "Bogo Ops/sec per Watt"
	show_kerns
	for l in $loads
	do
		echo -n "$l"
		for k in $kerns
		do
			w=$(grep Average $p-$l-$k.log | awk '{print $NF }')
			if [ "$w" == "" ]; then
				bperw=""
			else
				b=$(grep "cpu " $p-$l-$k-stress.log | awk '{print $(NF-1)}')
				if [ "$b" == "" ]; then
					b=0
				fi
				bperw=$(echo "scale=8; $b / $w" | bc)
			fi
			echo -n "$SEP$bperw" 
		done
		echo ""
	done
	echo ""

	echo "Package Temperature (Degree C)"
	show_kerns
	for l in $loads
	do
		echo -n "$l"
		for k in $kerns
		do
			t=$(grep "pkg" $p-$l-$k-stress.log | awk '{print $(NF-1)}')
			echo -n "$SEP$t"
		done
		echo ""
	done
	echo ""

	echo "Bogo Ops/sec per Degree C"
	show_kerns
	for l in $loads
	do
		echo -n "$l"
		for k in $kerns
		do
			t=$(grep "pkg" $p-$l-$k-stress.log | awk '{print $(NF-1)}')
			if [ "$t" == "" ]; then
				bpert=""
			else
				b=$(grep "cpu " $p-$l-$k-stress.log | awk '{print $(NF-1)}')
				if [ "$b" == "" ]; then
					b=0
				fi
				bpert=$(echo "scale=8; $b / $t" | bc)
			fi
			echo -n "$SEP$bpert"
		done
		echo ""
	done
	echo ""

	echo "Watts per Degree C"
	show_kerns
	for l in $loads
	do
		echo -n "$l"
		for k in $kerns
		do
			w=$(grep Average $p-$l-$k.log | awk '{print $NF }')
			if [ "$w" == "" ]; then
				wpert=""
			else
				t=$(grep "pkg" $p-$l-$k-stress.log | awk '{print $(NF-1)}')
				if [ "$t" == "" ]; then
					wpert=""
				else
					wpert=$(echo "scale=8; $w / $t" | bc)
				fi
			fi
			echo -n "$SEP$wpert"
		done
		echo ""
	done
done
