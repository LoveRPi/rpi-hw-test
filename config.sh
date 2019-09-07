#!/bin/bash

SOURCE_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
cd $SOURCE_DIR

CONFIG_FILE=.config
. "$CONFIG_FILE"

CONFIGS=(IPERF_IP WIFI_NAME WIFI_PASS)
CONFIGS_OPT=(IPERF_SPEED_LOW IPERF_WIRELESS_SPEED_LOW)

for i in "${CONFIGS[@]}"; do
	read -e -r -i "${!i}" -p "$i: " "$i"
	if grep "^$i=" "$CONFIG_FILE" > /dev/null; then
		sed -i "s/^$i=.*/$i=${!i}/" "$CONFIG_FILE"
	else
		echo "$i=${!i}" >> "$CONFIG_FILE"
	fi
done
