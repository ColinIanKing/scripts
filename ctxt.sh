#!/bin/bash

# Duration in seconds
DURATION=10

ctxt1=$(cat /proc/stat | grep ctxt | cut -d' ' -f2)
sleep $DURATION
ctxt2=$(cat /proc/stat | grep ctxt | cut -d' ' -f2)
rate=$(echo "scale=4; ( $ctxt2 - $ctxt1) / $DURATION" | bc)
echo "RATE: $rate context switches per second"
