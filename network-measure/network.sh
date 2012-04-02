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

#
# Syntax: network.sh [ wlan ] [ logfile ]
# Where wlan = name of wireless device (see ifconfig) e.g. wlan0
#
# Change log
#
# Colin King	--/01/2009	Initial Version
# Colin King	01/07/2009	Calculate averages
#
ECHO='echo -e'
SLEEP_DURATION=1

syntax() {
	echo "network.sh [wlan interface] [logfile]"
}


calc_bitrate()
{
	echo $1 | awk '{ printf "%5.2f", $1 * 8 / 1000000 }'
}


read_rx_tx()
{
	data=`ifconfig $wlan | grep "RX bytes"  | awk '{ print $2 " " $6 }' | sed 's/bytes://g'`
	read rx tx << EOF
	$data
EOF
}

read_quality()
{
	data=`cat /proc/net/wireless | grep $wlan | awk '{print $3 " " $4 " " $5}'`
	read link level noise << EOF
	$data
EOF
}

calc_deltas()
{
	let rx_delta=$rx-$last_rx
	let tx_delta=$tx-$last_tx
	last_rx=$rx
	last_tx=$tx
	rx_delta_br=`calc_bitrate $rx_delta`
	tx_delta_br=`calc_bitrate $tx_delta`
}

integer()
{
	echo $1 | awk '{ printf "%d", $1 }'
}

calc_totals()
{
	let rx_total=$rx_total+$rx_delta
	let tx_total=$tx_total+$tx_delta
	let link_total=$link_total+`integer $link`
	let level_total=$level_total+`integer $level`
	let noise_total=$noise_total+`integer $noise`
}

output()
{
	$ECHO $* >> $LOG_FILE
	$ECHO $*
}

header()
{
	output 'RX\tTX\tRX\tTX\tLink\tLevel\tNoise' 
	output 'Bytes/S\tBytes/S\tMBits/s\tMBits/s\tQuality\tQuality\tQuality' 
}

calc_averages()
{
	if [ $secs -gt 0 ]; then
		rx_rate=`echo $rx_total $secs | awk '{ printf "%d", $1 / $2 }'`
		tx_rate=`echo $tx_total $secs | awk '{ printf "%d", $1 / $2 }'`
		link_rate=`echo $link_total $secs | awk '{ printf "%5.2f", $1 / $2 }'`
		level_rate=`echo $level_total $secs | awk '{ printf "%5.2f", $1 / $2 }'`
		noise_rate=`echo $noise_total $secs | awk '{ printf "%5.2f", $1 / $2 }'`
		rx_rate_br=`calc_bitrate $rx_rate`
		tx_rate_br=`calc_bitrate $tx_rate`
	else
		rx_rate="--"
		tx_rate="--"
		link_rate="--"
		level_rate="--"
		noise_rate="--"
		rx_rate_br="--"
		tx_rate_br="--"
	fi
	output " "
	output "Averages:"
	header 
	output "$rx_rate\t$tx_rate\t$rx_rate_br\t$tx_rate_br\t$link_rate\t$level_rate\t$noise_rate" 
}

complete()
{
	echo ""
	calc_averages
	output ""
	output "Test completed after $secs seconds of samples"
	exit 0
}


#
# Determine interface to measure
#
wlan=`ifconfig | grep wlan | cut -f 1  -d ' '`
if [ $# -gt 0 ]; then
	wlan=$1
	shift
fi
if [ x$wlan == x ]; then
	echo "Don't know which wifi interface to use!"
	syntax
	exit 1
fi
ifconfig $wlan >& /dev/null
if [ $? -ne 0 ]; then
	echo "Cannot seem to find network interface $wlan, aborting!"
	exit 1
fi

#
# Log name
#
LOG_FILE=$wlan.log
if [ $# -gt 0 ]; then
	LOG_FILE=$1
	shift
fi


$ECHO "Grabbing Statistics for $wlan and saving data to $LOG_FILE"
trap complete SIGINT

#
# Here we go..
#
echo "Test started on `date`" > $LOG_FILE
output ""
header

#
# Get initial stats
#
secs=0
last_rx=0
last_tx=0
rx_total=0
tx_total=0
link_total=0
level_total=0
noise_total=0
read_rx_tx
calc_deltas
sleep $SLEEP_DURATION
#
# Gather stats until ^C is hit
#
while true
do
	read_rx_tx
	calc_deltas
	read_quality
	calc_totals
	let secs=$secs+$SLEEP_DURATION
	output "$rx_delta\t$tx_delta\t$rx_delta_br\t$tx_delta_br\t$link\t$level\t$noise" 
	sleep $SLEEP_DURATION
done
