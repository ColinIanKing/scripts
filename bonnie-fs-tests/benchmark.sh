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


DEV=/dev/mmcblk0p1

for I in ext2 ext3 ext4 xfs jfs reiserfs vfat
do
	echo Filesystem: $I
	echo y | mkfs.$I $DEV
	sync; sleep 1; sync; sleep 1; sync
	fsck $DEV
	mount -o $DEV /mnt
	mkdir /mnt/test
	bonnie++ -d /mnt/test -r 1 -s 7 -u 0:0 
	umount /mnt
done
