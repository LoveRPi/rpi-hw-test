#!/bin/bash

SOURCE_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
cd $SOURCE_DIR

apt-get install -y kmscube iperf network-manager mesa-utils-extra
BOOT_CONFIG_FILE=/boot/config.txt
sed -i s/^#dtoverlay=vc4-fkms-v3d/dtoverlay=vc4-fkms-v3d/ "$BOOT_CONFIG_FILE"
sed -i s/^\\[pi4\\]\\s\*\$/\\0\\ndtoverlay=dwc2,dr_mode=host/ "$BOOT_CONFIG_FILE"
#if ! grep ^hdmi_enable_4k60 "$BOOT_CONFIG_FILE" > /dev/null; then
#	sed -i s/^\\[pi4\\]\\s\*\$/\\0\\nhdmi_enable_4kp60=1/ "$BOOT_CONFIG_FILE"
#fi
systemctl disable dhcpcd
sed -i s/^managed=false/managed=true/ /etc/NetworkManager/NetworkManager.conf
GETTY_TTY1_OVERRIDE_FILE=/etc/systemd/system/getty@tty1.service.d/override.conf
cp systemd.getty@tty1.override.conf "$GETTY_TTY1_OVERRIDE_FILE"
sed -i s/^ExecStart=-/\\0${PWD//\//\\\/}\\/test.sh/ "$GETTY_TTY1_OVERRIDE_FILE"
