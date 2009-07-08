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
# Some arbitary webcam USB vendor,product IDs:
IDVENDOR=0acf
IDPRODUCT=1126
#
# And turn on USB persist
#
for I in /sys/bus/usb/devices/*/*
do
  if [ -e $I/$IDVENDOR -a -e $I/$IDPRODUCT ]; then
    idvendor=`cat $I/idVendor`
    idproduct=`cat $I/idProduct`
    if [ x$idvendor = x$IDVENDOR -a x$idproduct = x$IDPRODUCT ]; then
      if [ -e $I/../power/persist ]; then
        echo 1 > $I/power/persist
      fi
      if [ -e $I/../power/persist ] ; then
	echo 1 > $I/../power/persist
      fi
    fi
  fi
done
