#!/bin/bash

SOURCE_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
cd $SOURCE_DIR

apt-get install -y kmscube iperf network-manager
sed -i s/^#dtoverlay=vc4-fkms-v3d/dtoverlay=vc4-fkms-v3d/ /boot/config.txt
systemctl disable dhcpcd
sed -i s/^managed=false/managed=true/ /etc/NetworkManager/NetworkManager.conf
GETTY_TTY1_OVERRIDE_FILE=/etc/systemd/system/getty@tty1.service.d/override.conf
cp systemd.getty@tty1.override.conf "$GETTY_TTY1_OVERRIDE_FILE"
sed -i s/^ExecStart=-/\\0${PWD//\//\\\/}\\/test.sh/ "$GETTY_TTY1_OVERRIDE_FILE"
