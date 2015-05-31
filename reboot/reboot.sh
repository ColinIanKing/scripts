#!/bin/bash
sync
sleep 1;
sync
echo -e '\xe' | sudo dd of=/dev/port bs=1 seek=3321
