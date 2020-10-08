#!/bin/bash

RPI_getRevision(){
	if [ -z "$1" ]; then
		echo "$0 REVISION_CODE" >&2
		return 1
	fi
	case "$1" in
		a03111 | b03111 | c03111)
			PI_VER=4B
			PI_VER_TEXT="${COLOR_GREEN}Raspberry Pi 4 Model B 1.1 Manufactured by Sony UK${COLOR_NO}"
			;;
		b03112 | c03112)
			PI_VER=4B
			PI_VER_TEXT="${COLOR_GREEN}Raspberry Pi 4 Model B 1.2 Manufactured by Sony UK${COLOR_NO}"
			;;
		d03114)
			PI_VER=4B
			PI_VER_TEXT="${COLOR_GREEN}Raspberry Pi 4 Model B 1.4 Manufactured by Sony UK${COLOR_NO}"
			;;
		a020d3)
			PI_VER=3BP
			PI_VER_TEXT="${COLOR_GREEN}Raspberry Pi 3 Model B+ 1.3 Manufactured by Sony UK${COLOR_NO}"
			;;
		a02082)
			PI_VER=3B
			PI_VER_TEXT="${COLOR_RED}Raspberry Pi 3 Model B 1.2 Manufactured by Sony UK${COLOR_NO}"
			;;
		a22082)
			PI_VER=3B
			PI_VER_TEXT="${COLOR_GREEN}Raspberry Pi 3 Model B 1.2 Manufactured by Embest${COLOR_NO}"
			;;
		a22083)
			PI_VER=3B
			PI_VER_TEXT="${COLOR_GREEN}Raspberry Pi 3 Model B 1.3 Manufactured by Embest${COLOR_NO}"
			;;
		a32082)
			PI_VER=3B
			PI_VER_TEXT="${COLOR_RED}Raspberry Pi 3 Model B 1.2 Manufactured by Sony Japan${COLOR_NO}"
			;;
		a52082)
			PI_VER=3B
			PI_VER_TEXT="${COLOR_RED}Raspberry Pi 3 Model B 1.2 Manufactured by Stadium${COLOR_NO}"
			;;
		*)
			PI_VER=UNKNOWN
			PI_VER_TEXT="${COLOR_RED}Unable to determine Raspberry Pi code.${COLOR_NO}"
			;;
	esac
	echo "$PI_VER $PI_VER_TEXT"
}

RPI_getMemory(){
	if [ -z "$1" ]; then
		echo "$0 PI_VERSION" >&2
		return 1
	fi
	PI_MEM_MB=$(free --mega | grep ^Mem | tr -s " " | cut -f 2 -d " ")
	PI_MEM_GB=$(((PI_MEM_MB+512)/1024))
	case "$1" in
		4B)
			echo "Memory Size: ${COLOR_GREEN}${PI_MEM_GB}GB${COLOR_NO}"
			;;
		3BP | 3B)
			if [ $PI_MEM_GB -ne 1 ]; then
				echo "Memory Size: ${COLOR_RED}${PI_MEM_GB}GB${COLOR_NO}"
			else
				echo "Memory Size: ${COLOR_GREEN}${PI_MEM_GB}GB${COLOR_NO}"
			fi
			;;
		*)
			echo "${COLOR_RED}Unknown Pi Version${COLOR_NO}" >&2
			return 1
			;;
	esac
}	

RPI_getSerialNumber(){
	PI_SN=$(grep ^Serial /proc/cpuinfo | cut -f 2 -d " ")
	if [ -z "$PI_SN" ]; then
		echo "${COLOR_RED}Unknown Pi Serial Number${COLOR_NO}" >&2
		return 1
	fi
	echo "Serial Number: ${COLOR_GREEN}${PI_SN}${COLOR_NO}"
}


