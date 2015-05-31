#!/bin/bash

if [ $EUID -ne 0 ]; then
	echo "Need to run this as root, use sudo!"
	exit 1;
fi

TURBO_DISENGAGE=$((1 << 32))
TURBO_MASK=$((1 << 38))
IA32_PERF_CTL=0x199
IA32_MISC_ENABLE=0x1a0
IA32_ENERGY_PERF_BIAS=0x1b0
IA32_CLOCK_MODULATION=0x19a

# 0 => undefined
# 1 => 12.5%
# ..
# 6 => 75.0%
# 7 => 87.5%
MODULATION_SETTING=6

which rdmsr >& /dev/null
if [ $? -eq 1 ]; then
	echo "You need to install msr-tools: sudo apt-get install msr-tools"
	exit 1
fi

if [ ! -e /dev/cpu/0/msr ]; then
	modprobe msr
fi

if [ ! -e /dev/cpu/0/msr ]; then
	echo "Cannot access MSR interface. Aborting!"
	exit 1
fi

cpus=$(grep processor /proc/cpuinfo | wc -l)
echo "Your machine has $cpus CPUS"

#
#  Disable Turbo
#
echo "Disabling CPU Turbo"
for i in $(seq 0 $((cpus - 1)))
do
	v=$(rdmsr -p$i $IA32_MISC_ENABLE -d)
	t=$((v & $TURBO_MASK))
	v=$((v | $TURBO_MASK))
	wrmsr -p$i $IA32_MISC_ENABLE $v >& /dev/null
done

#
# Set lowest energy preference
#
echo "Adjusting CPU energy preference"
for i in $(seq 0 $((cpus - 1)))
do
	v=$(rdmsr -p$i $IA32_ENERGY_PERF_BIAS -d)
	# Set lowest energy policy pref
	wrmsr -p$i $IA32_ENERGY_PERF_BIAS 0 >& /dev/null
done

#
# Set clock modulation (evil hack)
#
echo "Adjusting CPU clock modulation"
for i in $(seq 0 $((cpus - 1)))
do
	v=$((MODULATION_SETTING << 1))
	v=$((v + 16))
	wrmsr -p$i $IA32_CLOCK_MODULATION $v >& /dev/null
done

#for i in $(seq 0 $((cpus - 1)))

#for i in $(seq 0 $((cpus - 1)))
#do
#	v=$(rdmsr -p$i $IA32_PERF_CTL -d)
#	echo $v
#	v=$((v | $TURBO_DISENGAGE))
#	wrmsr -p$i $IA32_PERF_CTL $v
#done

