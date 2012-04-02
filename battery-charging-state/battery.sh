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

current=`grep remaining /proc/acpi/battery/BAT1/state | tr -d A-z | tr -d " " | tr -d :`

total=`grep "design capacity:" /proc/acpi/battery/BAT1/info | tr -d A-z | tr -d " " | tr -d :`

rate=`grep "present rate:" /proc/acpi/battery/BAT1/state | tr -d A-z | tr -d " " | tr -d :`

percent=`bc << EOF
100.0 * $current / $total
EOF
`
if [ $rate -eq  0 ]; then
  echo $percent'%, charging'
else
hours=`bc << EOF
  (1.0*$current) / (1.0*$rate) 
EOF
`
minutes=`bc << EOF
  60.0 * $current / $rate - $hours * 60
  EOF
`
echo $percent'%, '$hours':'$minutes
fi
