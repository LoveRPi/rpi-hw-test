#!/bin/bash

SOURCE_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
cd $SOURCE_DIR

CONFIG_FILE=.config
if [ -f "$CONFIG_FILE" ]; then
	. "$CONFIG_FILE"
else
	touch "$CONFIG_FILE"
fi

. config-keys.sh

for i in "${CONFIGS[@]}"; do
	while true; do
		read -e -r -i "${!i}" -p "$i: " "$i"
		if [ -z "${!i}" ]; then
			echo "$i is a mandatory field."
		else
			break
		fi
	done
	if grep "^$i=" "$CONFIG_FILE" > /dev/null; then
		sed -i "s/^$i=.*/$i=${!i}/" "$CONFIG_FILE"
	else
		echo "$i=${!i}" >> "$CONFIG_FILE"
	fi
done

for i in "${CONFIGS_OPT[@]}"; do
	read -e -r -i "${!i}" -p "$i (Optional): " "$i"
	if [ -z "${!i}" ]; then
		if grep "^$i=" "$CONFIG_FILE" > /dev/null; then
			sed -i "/^$i=/d" "$CONFIG_FILE"
		fi
	else
		if grep "^$i=" "$CONFIG_FILE" > /dev/null; then
			sed -i "s/^$i=.*/$i=${!i}/" "$CONFIG_FILE"
		else
			echo "$i=${!i}" >> "$CONFIG_FILE"
		fi
	fi
done
