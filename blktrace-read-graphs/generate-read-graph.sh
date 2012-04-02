#!/bin/sh

# Copyright (C) 2012 Canonical
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

syntax()
{
	echo "Syntax: generate-read-graphs blktracefile [points-per-sec]"
	echo "e.g.    generate-read-graphs example.blktrace. 0.25"
	exit 1
}

if [ $# -lt 1 -o $# -gt 2 ]; then
	syntax
fi 

points_per_sec=0.1
if [ $# -eq 2 ]; then
	points_per_sec=$2
fi

#
# output graph file name
#
graphfile=graph-reads.png
#
#
tmpfile=/tmp/parsed.log.$$
tmpfileavg=/tmp/parsed.log.avg.$$
blkparse -i $1 | awk '
{ 
	if ($6 == "C") {
     		if (index($7,"R")>0) {
			blks=$10
     			print $4 "\t" $10 
		}
	}
}' | awk -v delta=$points_per_sec '
{ 
     	time=$1;
	total += $2
     	if (time > (start + delta)) {
		if (delta > 0) 
     			print time-(delta/2) "\t" 0 "\t " 0 "\t" ((total * 512) / delta)/(1024 * 1024)
		start=time
		total=0
	}
}
' > $tmpfile

blkparse -i $1 | awk '
{ 
	if ($6 == "C") {
     		if (index($7,"R")>0) {
			time=$4
			total += $10
		}
	}
}
END { 
	average=((total * 512) / time)/(1024 * 1024); 
	print 0, average
	print time, average
}
' > $tmpfileavg


cat <<EOF | gnuplot
set output "$graphfile"
set terminal png transparent font "arial" 8
set title "Read Rate"
set xlabel "Time (Seconds)"
set ylabel "Data Rate (MB/S)"
set xrange [0:]
set yrange [0:]
plot '$tmpfile' using 1:4 with lines title "Read Rate", \
     '$tmpfileavg' using 1:2 with lines title "Average Rate"
EOF
rm $tmpfile
rm $tmpfileavg
echo Generated graph: $graphfile
