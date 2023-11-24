#!/bin/bash

set -e

echo "Changing internal IP address"
sed -i 's/10.152.152.11/10.152.152.12/' /etc/network/interfaces.d/30_non-qubes-whonix

echo "Disabling graphical environment"
echo "rads_start_display_manager=0" >> /etc/rads.d/50_user.conf

echo "Opening ports 9735 and 9911"
echo 'EXTERNAL_OPEN_PORTS+=" 9735 9911 "' >> /etc/whonix_firewall.d/50_user.conf
whonix_firewall

echo "Adding user that LND will run as"
useradd -m -s /bin/bash lightning
echo "Adding user that will run backups"
useradd -s /bin/bash backup

echo "Adding service file for LND"
cp lnd.service /etc/systemd/system/

echo "Moving LND config file to its correct location"
mkdir /home/lightning/.lnd
cp lnd.conf /home/lightning/.lnd/lnd.conf
chown -R lightning:lightning /home/lightning/.lnd
chmod -R 700 /home/lightning/.lnd
# start service with
# systemctl enable lnd
# systemctl start lnd
