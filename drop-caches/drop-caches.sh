#!/bin/sh
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
if [ x`whoami` != x'root' ]; then
	echo need to run with root permisions.
	exit 1
fi
#
# Paranoid - sync
#
echo -n "Sync.."
sync; sleep 1
echo -n "."
sync; sleep 1
echo -n "."
sync; sleep 1
echo -n "."
echo "Done!"
#
# And free up caches
#
echo Freeing the page cache:
echo 1 > /proc/sys/vm/drop_caches
echo Free dentries and inodes:
echo 2 > /proc/sys/vm/drop_caches
echo Free the page cache, dentries and the inodes:
echo 3 > /proc/sys/vm/drop_caches
