#!/bin/bash
########################################################################
#
# Written by Mike Kelly
# twitter.com/lixmk
# git.io/lixmk
# exfil.co
# 2016
#
# Updated for Raspberry Pi 3 B+ compatibility in 2025
#
########################################################################
####################                                ####################
####################     Wiegotcha fixclock.sh      ####################
####################                                ####################
########################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
########################################################################
########################################################################
#
#
echo -e "\e[0;31m#############################################################\e[0m"
echo -e "\e[0;31m#\e[0m                                                           \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m      This script will fix the hardware clock and set      \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m          the correct time and date for Wiegotcha          \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m                                                           \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m Ensure ethernet is connected then press ENTER to continue \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m                                                           \e[0;31m#\e[0m"
echo -e "\e[0;31m#############################################################\e[0m"
read -e NULL

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "[!] This script must be run as root"
  exit 1
fi

# Check if systemd-timesyncd is running (newer Raspberry Pi OS)
if systemctl is-active systemd-timesyncd >/dev/null 2>&1; then
  echo "[*] Stopping systemd-timesyncd"
  systemctl stop systemd-timesyncd
  sleep 2
# Fall back to traditional NTP if systemd-timesyncd is not available
elif [ -f /etc/init.d/ntp ]; then
  echo "[*] Stopping ntp"
  /etc/init.d/ntp stop
  sleep 2
fi

# Ensure i2c modules are loaded
echo "[*] Ensuring I2C modules are loaded"
modprobe i2c-bcm2708 2>/dev/null || modprobe i2c-bcm2835 2>/dev/null
sleep 1

# Check if DS3231 device exists, create if not
if [ ! -e /sys/class/i2c-adapter/i2c-1/1-0068 ]; then
  echo "[*] Creating DS3231 device"
  echo ds3231 0x68 > /sys/class/i2c-adapter/i2c-1/new_device
  sleep 2
fi

# Setting correct time using timeserver
echo "[*] Setting correct time/date from internet time servers"
if command -v ntpd >/dev/null 2>&1; then
  ntpd -q -g
elif command -v ntpdate >/dev/null 2>&1; then
  ntpdate -u pool.ntp.org
else
  # If neither ntpd nor ntpdate is available, try using timedatectl
  timedatectl set-ntp true
  sleep 2
  timedatectl set-ntp false
fi
sleep 2

# Setting hardware clock from system time
echo "[*] Setting hardware clock"
hwclock -w
sleep 1

# Restart time synchronization service
if systemctl is-active systemd-timesyncd >/dev/null 2>&1; then
  echo "[*] Restarting systemd-timesyncd"
  systemctl start systemd-timesyncd
elif [ -f /etc/init.d/ntp ]; then
  echo "[*] Restarting ntp"
  /etc/init.d/ntp start
fi
sleep 2

# Double check
echo "[*] Clock should be fixed now."
echo "[*] Confirm the following times match and that they are correct."
hwclock -r && date
exit 0
