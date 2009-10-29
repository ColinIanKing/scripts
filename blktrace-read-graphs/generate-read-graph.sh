#!/bin/sh

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
blkparse -i $1 | awk '
{ 
	if ($6 == "D") {
     		if (index($7,"R")>0) {
			i=sprintf("%s.%s",$8,$10)
			starttime[i]=$4
		}
	}
	if ($6 == "C") {
     		if (index($7,"R")>0) {
			i=sprintf("%s.%s",$8,$10)
			blks=$10
			endtime=$4
			deltatime=endtime-starttime[i]
     			print (endtime+starttime[i])/2 "\t" $8 "\t " $10 "\t" ((blks / deltatime) * 512)/(1024*1024) 
		}
	}
}' | awk -v delta=$points_per_sec '
{ 
     	time=$1;
	total += $3
     	if (time > (start + delta)) {
     		print time-(delta/2) "\t" 0 "\t " 0 "\t" ((total*512)/(1024*1024)) / delta
		start=time
		total=0
	}
}
' > $tmpfile
cat <<EOF | gnuplot
set output "$graphfile"
set terminal png transparent font "arial" 8
set title "Read Rate during Boot"
set xlabel "Time (Seconds)"
set ylabel "Data Rate (MB/S)"
set xrange [0:]
set yrange [0:]
plot '$tmpfile' using 1:4 with lines title "Read Rate"
EOF
rm $tmpfile
echo Generated graph: $graphfile
