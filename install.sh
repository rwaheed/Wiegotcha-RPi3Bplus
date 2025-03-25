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
# Repository: https://github.com/rwaheed/Wiegotcha-RPi3Bplus
#
########################################################################
######################                            ######################
######################  Wiegotcha Install Script  ######################
######################                            ######################
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
echo -e "\e[0;31m#\e[0m     This script script will install and configure all     \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m     necessary dependancies and services for Wiegotcha     \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m                                                           \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m       This script is not completely automated some        \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m     interaction is required. Watch for prompts in red     \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m                                                           \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m         Additionally Wiegotcha is intended to be          \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m       installed on a fresh, dedicated raspberry pi        \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m                                                           \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m    CTRL-C now to quit now or press ENTER to continue.     \e[0;31m#\e[0m"
echo -e "\e[0;31m#\e[0m                                                           \e[0;31m#\e[0m"
echo -e "\e[0;31m#############################################################\e[0m"
read -e NULL

echo "[*] Starting installation."

#Checking if root. Will sudo
USER="$(whoami)"
if [ "$USER" != "root" ]
then
  echo "[!] Not running as root."
  echo -e "\e[0;31m[*] Switching to root. Enter root password.\e[0m"
  sudo su -
else
  echo "[*] cd'ing into /root/."
  cd ~
fi

#Changing root pw if approved
echo -e "\e[0;31m[+] Do you want to change the root password?\e[0m"
echo -n "[+] 'yes' or 'no': "
read -e RESP1
if [ "$RESP1" = "yes" ]
then
  echo -e "\e[0;31m[+] Set root password.\e[0m"
  passwd
  echo "[*] root password set."
else
  echo "[*] Not changing root password."
fi

#Checking to allow root ssh login
echo -e "\e[0;31m[+] Do you want to allow root via ssh?\e[0m"
echo "[+] Doing so may present a security risk, especially if defaults are left."
echo "[+] but will allow for greater ease of use in the field."
echo -n "[+] 'yes' or 'no': "
read -e RESP2
if [ "$RESP2" = "yes" ]
then
  echo "[*] Modding sshd_config to allow root ssh login."
  sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
else
  echo "[*] Root SSH login not permitted."
fi
#Changing pi password
echo -e "\e[0;31m[+] Do you want to change the pi user password?\e[0m"
echo -n "[+] 'yes' or 'no': "
read -e RESP3
if [ "$RESP3" = "yes" ]
then
  echo -e "\e[0;31m[+] Set pi password.\e[0m"
  passwd pi
  echo "[*] pi password set."
else
  echo "[!] Ensure pi password is no longer default before field use."
fi

#Proceding with installation
echo "[*] Proceeding with installation."
echo "[*] Updating Raspberry Pi OS. This could take a while..."
apt-get update
apt-get -y dist-upgrade
apt-get -y install apache2 hostapd isc-dhcp-server screen ntpdate git build-essential
echo "[*] Updating complete."

#Changing hostname for purely vain reasons
echo "[*] Setting Wiegotcha hostname"
sed -i 's/raspberrypi/Wiegotcha/g' /etc/hosts
echo 'Wiegotcha' > /etc/hostname

#Installing WiringPi (updated method for newer Raspberry Pi OS)
echo "[*] Installing WiringPi."
if [ -d "/root/WiringPi" ]; then
  echo "[*] Removing existing WiringPi directory"
  rm -rf /root/WiringPi
fi

echo "[*] Cloning WiringPi from GitHub (maintained fork)"
git clone https://github.com/WiringPi/WiringPi.git
cd WiringPi
./build
cd ~/

#Copying Wiegotcha specific conf files
#Configs include: dhcpd, hostapd, interfaces, rc.local, and default html pages
echo "[*] Copying config files"
cd ./Wiegotcha/
cp ./confs/dhcpd.conf /etc/dhcp/
cp ./confs/hostapd.conf /etc/hostapd/
cp ./confs/interfaces /etc/network/
cp -R ./html/* /var/www/html/
cp ./confs/rctmp.local /etc/rc.local
cp ./laststep.sh ../
mkdir -p /var/www/html/backup/
sed -i 's|#DAEMON_CONF=""|DAEMON_CONF=/etc/hostapd/hostapd.conf|g' /etc/default/hostapd
echo "[*] Compiling Wiegotcha C code"
gcc -o ../wiegotcha wiegotcha.c -L/usr/local/lib -lwiringPi -lpthread

#Enable i2c on boot for hardware clock (automated method)
echo "[*] Enabling I2C interface automatically"
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
  echo "dtparam=i2c_arm=on" >> /boot/config.txt
fi

if ! grep -q "^i2c-dev" /etc/modules; then
  echo "i2c-dev" >> /etc/modules
fi

if ! grep -q "^i2c-bcm2708" /etc/modules; then
  echo "i2c-bcm2708" >> /etc/modules
fi

# Install I2C tools
apt-get -y install i2c-tools

# Create a screen session that will survive the reboot
echo "[*] Creating installation screen session"
cat > /root/continue_install.sh << 'EOF'
#!/bin/bash
cd /root
./laststep.sh
EOF

chmod +x /root/continue_install.sh

# Start a detached screen session that will run after reboot
screen -dmS install -L /root/continue_install.sh

echo -e "\e[0;31m[+] The system will now reboot. After reboot, login then 'sudo su -' (or login as root)\e[0m"
echo -e "\e[0;31m[+] Once you're root, type 'screen -dr install' to complete the installation.\e[0m"
reboot
