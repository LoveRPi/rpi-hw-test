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


