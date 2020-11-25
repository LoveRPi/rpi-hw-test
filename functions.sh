#!/bin/bash

RPI_getVersion(){
	if [ -z "$1" ]; then
		echo "$0 REVISION_CODE TEXT" >&2
		return 1
	fi
	if [ "$1" = "Firefly roc-rk3328-cc" ]; then
		PI_VERSION=roc-rk3328-cc
		PI_VERSION_TEXT="ROC-RK3328-CC Renegade"
	fi
	if [ -z "$2" ]; then
		echo "$PI_VERSION"
	else
		echo "$PI_VERSION_TEXT"
	fi
}

RPI_getMemory(){
	PI_MEM_MB=$(free --mega | grep ^Mem | tr -s " " | cut -f 2 -d " ")
	PI_MEM_GB=$(((PI_MEM_MB+512)/1024))
	echo "${PI_MEM_GB}"
}	

RPI_getSerialNumber(){
	PI_SN=$(hexdump -n 16 /sys/devices/platform/ff260000.efuse/rockchip-efuse0/nvmem | cut -f 2- -d " " | head -n 1)
	if [ -z "$PI_SN" ]; then
		echo "Unknown Pi Serial Number" >&2
		return 1
	fi
	echo "${PI_SN}"
}

RPI_getMinNetworkSpeed(){
	if [ -z "$1" ]; then
		echo "$0 PI_VERSION WIRELESS" >&2
		return 1
	fi
	case $1 in
		roc-rk3328-cc)
			WIRED_SPEED_MIN=750
			WIRELESS_SPEED_MIN=0
			;;
		*)
			echo "Unknown Board Version." >&2
			return 1
			;;
	esac
	if [ -z "$2" ]; then
		echo $WIRED_SPEED_MIN
	else
		echo $WIRELESS_SPEED_MIN
	fi
}

RPI_getVoltageStatus(){
	echo 0
}

RPI_getHDMIModes(){
	if [ -z "$1" ]; then
		echo "$0 PI_VERSION" >&2
		return 1
	fi
	HDMI_MODES_SYS_FILE=/sys/class/drm/card0/card0-HDMI-A-1/modes
	if [ ! -e "$HDMI_MODES_SYS_FILE" ]; then
		HDMI_MODES_SYS_FILE=/sys/class/drm/card1/card1-HDMI-A-1/modes
		if [ ! -e "$HDMI_MODES_SYS_FILE" ]; then
			echo "HDMI modes file missing!" >&2
			return 1
		fi
	fi
	cat $HDMI_MODES_SYS_FILE
}

RPI_getEthernet(){
	ETHERNET=
	for eth in /sys/class/net/e*; do
		ETHERNET=$eth
	done
	if [ -z "$ETHERNET" ]; then
		echo "Ethernet not found." >&2
		return 1
	fi
	ETHERNET=${ETHERNET##*/}
	echo $ETHERNET
}

