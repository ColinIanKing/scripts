#!/bin/sh 

#
# Copyright (C) 2009 Canonical
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
# Scan through all usb devices to find usb storage devices
# and set them to persistent storage
#
for I in /sys/bus/usb/devices/*/*
do
  if [ -e $I/uevent ]
  then
#
# For some reason [ -r $I/uevent ] returns
# true for some uevent files even when they
# are not readable, hence we stat them as
# and check if they are not writable too
#
    statflags=`stat -c %a $I/uevent`
    if [ -r $I/uevent -a x$statflags != 'x200' ]
    then
#
# Is the device a USB storage device?
#
      usbstorage=`grep DRIVER=usb-storage $I/uevent`
      if [ x$usbstorage != x ]
      then
#
# If persist exists, set it
#
        if [ -e $I/../power/persist ]
        then
          echo setting persistant for $I
          echo 1 > $I/../power/persist
        fi
     fi
  fi
fi
done
