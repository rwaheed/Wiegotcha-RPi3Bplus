# Wiegotcha RFID Thief - Installation Guide for Raspberry Pi 3 B+

This guide provides step-by-step instructions for installing and configuring the Wiegotcha RFID Thief on a Raspberry Pi 3 B+. The code has been updated to ensure compatibility with current Raspberry Pi OS versions and the Raspberry Pi 3 B+ hardware.

## Hardware Requirements

- Raspberry Pi 3 B+
- DS3231 Real-time Clock Module
- Level Shifter (for converting 5V to 3.3V signals)
- RFID Reader (HID MaxiProx 5375, HID R90, or Indala ASR-620)
- 12V Battery with 5V USB output
- MicroSD Card (8GB or larger)
- Jumper wires
- Short USB Micro Cable
- Optional: Haptic Motor (to replace speaker for silent operation)

## Software Installation

### Method 1: Manual Installation (Recommended)

1. Start with a fresh installation of Raspberry Pi OS (formerly Raspbian) on your SD card.

2. Boot your Raspberry Pi 3 B+ and ensure it has internet connectivity.

3. Open a terminal and run the following commands:

```bash
# Update the system
sudo apt-get update
sudo apt-get -y upgrade

# Install Git if not already installed
sudo apt-get -y install git

# Clone the updated Wiegotcha repository
cd ~
git clone https://github.com/yourusername/Wiegotcha-RPi3Bplus.git Wiegotcha

# Run the installation script
cd Wiegotcha
sudo ./install.sh
```

4. Follow the on-screen prompts during installation. The script will:
   - Update your system
   - Install required dependencies
   - Configure the wireless access point
   - Set up the hardware clock
   - Compile and install the Wiegotcha software

5. After the first reboot, log back in and complete the installation:

```bash
sudo su -
screen -dr install
```

6. After the second reboot, your Wiegotcha should be fully operational.

### Method 2: Using Pre-built Image (Coming Soon)

A pre-built image for Raspberry Pi 3 B+ will be available soon. This will allow you to simply write the image to an SD card and boot your Raspberry Pi with minimal configuration.

## Hardware Installation

1. **Prepare the Hardware Clock**: Place the DS3231 RTC module on the Raspberry Pi's GPIO pins starting at pin 1 (top left), going down the left side to pin 9.

2. **Connect the Level Shifter**:
   - RPi pin 4 to Level Shifter HV in
   - RPi pin 6 to Level Shifter LV gnd
   - RPi pin 11 to Level Shifter LV 1
   - RPi pin 12 to Level Shifter LV 4
   - RPi pin 17 to Level Shifter LV in

3. **Connect the RFID Reader**:
   - Reader TB1-3 to Battery Ground (Black)
   - Reader TB1-1 to Battery 12V (Red)
   - Reader TB2-1 to Level Shifter HV 1
   - Reader TB2-2 to Level Shifter HV 4
   - Reader TB1-2 to Level Shifter HV gnd

4. **Disable the Speaker** (for stealth operation):
   - Option 1: Desolder or snip the speaker to completely disable all audio output
   - Option 2: Adjust the DIP switches on the reader PCB (push switch 4 of SW1 to the OFF position)
   - Option 3: Replace the speaker with a small haptic motor (connect red wire to + and blue wire to -)

5. **Set Power Jumper**: Since we're using a 12V power supply, move the P2 jumper from pins 2-3 to pins 1-2.

6. **Secure Components**: Use velcro or tape to secure the Raspberry Pi inside the reader case and route wires through the small slit at the top of the reader.

## Post-Installation Configuration

### Setting the Clock

If your hardware clock time is incorrect, connect your Raspberry Pi to the internet via Ethernet and run:

```bash
sudo /root/Wiegotcha/fixclock.sh
```

### Accessing the Web Interface

1. Connect to the Wiegotcha wireless network:
   - SSID: Wiegotcha
   - Password: Wiegotcha (change this for security!)

2. Open a web browser and navigate to http://192.168.150.1

3. The web interface will automatically refresh every 5 seconds to display captured credentials.

### Changing Default Passwords

For security, you should change the default passwords:

1. Change Linux user passwords:
   ```bash
   sudo passwd root
   sudo passwd pi
   ```

2. Change the wireless access point password:
   ```bash
   sudo nano /etc/hostapd/hostapd.conf
   ```
   Find the line with `wpa_passphrase=Wiegotcha` and change it to your preferred password.
   Save and exit (Ctrl+X, Y, Enter).
   
3. Restart the hostapd service:
   ```bash
   sudo systemctl restart hostapd
   ```

## Troubleshooting

### Hardware Clock Issues

If the hardware clock is not working correctly:

1. Ensure the DS3231 module is properly connected to the GPIO pins
2. Run `sudo i2cdetect -y 1` to verify the I2C device is detected (should show "68")
3. Run the fixclock.sh script: `sudo /root/Wiegotcha/fixclock.sh`

### RFID Reader Not Working

If the RFID reader is not capturing badges:

1. Check all wiring connections between the Raspberry Pi, level shifter, and RFID reader
2. Verify the reader is receiving power (12V)
3. Check the Wiegotcha service status: `sudo systemctl status wiegotcha`
4. Check the logs: `sudo journalctl -u wiegotcha`

### Web Interface Not Accessible

If you cannot access the web interface:

1. Verify you're connected to the Wiegotcha wireless network
2. Check the hostapd service: `sudo systemctl status hostapd`
3. Check the Apache service: `sudo systemctl status apache2`
4. Restart the services if needed:
   ```bash
   sudo systemctl restart hostapd
   sudo systemctl restart apache2
   ```

## Additional Information

- All captured badges are stored in `/var/www/html/data.csv`
- Previous data is backed up to `/var/www/html/backup/<TIMESTAMP>.data.csv` at each boot
- Directory indexing is enabled for easy browsing of backed-up badges (http://192.168.150.1/backup/)

For more information and updates, visit the original project page: https://exfil.co/2017/01/17/wiegotcha-rfid-thief/
