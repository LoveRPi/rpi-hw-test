#!/bin/bash

RPI_getVersion(){
	if [ -z "$1" ]; then
		echo "$0 REVISION_CODE TEXT" >&2
		return 1
	fi
	case "$1" in
		a03111 | b03111 | c03111)
			PI_VERSION=4B
			PI_VERSION_TEXT="Raspberry Pi 4 Model B 1.1 Manufactured by Sony UK"
			;;
		b03112 | c03112)
			PI_VERSION=4B
			PI_VERSION_TEXT="Raspberry Pi 4 Model B 1.2 Manufactured by Sony UK"
			;;
		d03114)
			PI_VERSION=4B
			PI_VERSION_TEXT="Raspberry Pi 4 Model B 1.4 Manufactured by Sony UK"
			;;
		a020d3)
			PI_VERSION=3BP
			PI_VERSION_TEXT="Raspberry Pi 3 Model B+ 1.3 Manufactured by Sony UK"
			;;
		2a020d3)
			PI_VERSION=3BP
			PI_VERSION_TEXT="Raspberry Pi 3 Model B+ 1.3 Manufactured by Sony UK (Overclocked)"
			;;
		a02082)
			PI_VERSION=3B
			PI_VERSION_TEXT="Raspberry Pi 3 Model B 1.2 Manufactured by Sony UK"
			return 1
			;;
		a22082)
			PI_VERSION=3B
			PI_VERSION_TEXT="Raspberry Pi 3 Model B 1.2 Manufactured by Embest"
			;;
		a22083)
			PI_VERSION=3B
			PI_VERSION_TEXT="Raspberry Pi 3 Model B 1.3 Manufactured by Embest"
			;;
		a32082)
			PI_VERSION=3B
			PI_VERSION_TEXT="Raspberry Pi 3 Model B 1.2 Manufactured by Sony Japan"
			return 1
			;;
		a52082)
			PI_VERSION=3B
			PI_VERSION_TEXT="Raspberry Pi 3 Model B 1.2 Manufactured by Stadium"
			return 1
			;;
		*)
			echo "Unable to determine Raspberry Pi code." >&2
			return 1
			;;
	esac
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
	PI_SN=$(grep ^Serial /proc/cpuinfo | cut -f 2 -d " ")
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
		3B)
			WIRED_SPEED_MIN=90
			WIRELESS_SPEED_MIN=25
			;;
		3BP)
			WIRED_SPEED_MIN=250
			WIRELESS_SPEED_MIN=40
			;;
		4B)
			WIRED_SPEED_MIN=750
			WIRELESS_SPEED_MIN=40
			;;
		*)
			echo "Unknown Pi Version." >&2
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
	VOLTAGE_STATUS_HEX=`vcgencmd get_throttled | cut -f 2 -d x`
	VOLTAGE_STATUS_DEC=$((16#$VOLTAGE_STATUS_HEX))
	if [ -z "$2" ]; then
		echo $(((VOLTAGE_STATUS_DEC & 0x1) != 0))
	else
		echo $(((VOLTAGE_STATUS_DEC & 0x10000) != 0))
	fi
}

RPI_getHDMIModes(){
	if [ -z "$1" ]; then
		echo "$0 PI_VERSION" >&2
		return 1
	fi
	case $1 in
		4B)
			HDMI_MODES_SYS_FILE=/sys/class/drm/card0/card0-HDMI-A-1/modes
			if [ ! -e "$HDMI_MODES_SYS_FILE" ]; then
				HDMI_MODES_SYS_FILE=/sys/class/drm/card1/card1-HDMI-A-1/modes
			fi
			;;
		3B | 3BP)
			HDMI_MODES_SYS_FILE=/sys/class/drm/card0/card0-HDMI-A-1/modes
			;;
		*)
			echo "Unknown Pi Version." >&2
			return 1
			;;
	esac
	if [ ! -e "$HDMI_MODES_SYS_FILE" ]; then
		echo "HDMI modes file missing!" >&2
		return 1
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

