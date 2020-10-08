#!/bin/bash

SOURCE_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
cd $SOURCE_DIR

COLOR_RED=`tput setaf 1`
COLOR_GREEN=`tput setaf 2`
COLOR_NO=`tput sgr0`

if [ ! -f .config ]; then
	sleep 5
	echo "Please set the runtime configuration."
	./config.sh
fi

. config-keys.sh

while true; do
	. .config

	if [ ! -z "$DEBUG" ]; then
		set -x
	fi
	
	CONFIG_OK=1

	for key in "${CONFIGS[@]}"; do
		if [ -z "${!key}" ]; then
			echo "$key is a mandatory field."
			CONFIG_OK=0
			break
		fi
	done

	if [ "$CONFIG_OK" -eq 1 ]; then
		break
	fi
	
	./config.sh
done

function finish {
	pkill cpuburn-a53
	pkill kmscube
}
trap finish EXIT

. functions.sh

### REVISION ###
COLOR_NEXT="$COLOR_GREEN"
PI_REV=`grep Revision /proc/cpuinfo | cut -f 2 -d ' '`
PI_VER=$(RPI_getRevision $PI_REV)
PI_VER_TEXT=$(RPI_getRevision $PI_REV 1)
if [ $? -ne 0 ]; then
	COLOR_NEXT="$COLOR_RED"
fi
echo "${COLOR_NEXT}${PI_VER_TEXT}${COLOR_NO}"

if [ -z "$IPERF_SPEED_LOW" ]; then
	if [ "$PI_VER" = "3B" ]; then
		IPERF_SPEED_LOW=90
	elif [ "$PI_VER" = "3BP" ]; then
		IPERF_SPEED_LOW=250
	elif [ "$PI_VER" = "4B" ]; then
		IPERF_SPEED_LOW=500
	fi
fi

if [ -z "$IPERF_WIRELESS_SPEED_LOW" ]; then
	if [ "$PI_VER" = "3B" ]; then
		IPERF_WIRELESS_SPEED_LOW=25
	elif [ "$PI_VER" = "3BP" ]; then
		IPERF_WIRELESS_SPEED_LOW=50
	elif [ "$PI_VER" = "4B" ]; then
		IPERF_WIRELESS_SPEED_LOW=50
	fi
fi

### MEMORY ###
COLOR_NEXT="$COLOR_GREEN"
PI_MEM=$(RPI_getMemory)
if [ $? -ne 0 ]; then
	COLOR_NEXT="$COLOR_RED"
elif [ -z "$PI_MEM" ]; then
	COLOR_NEXT="$COLOR_RED"
elif [ "$PI_MEM" -lt 1 ]; then
	COLOR_NEXT="$COLOR_RED"
fi
echo "Memory Size: ${COLOR_NEXT}${PI_MEM}GB${COLOR_NO}"

### SERIAL ###
COLOR_NEXT="$COLOR_GREEN"
PI_SERIAL=$(RPI_getSerialNumber)
if [ $? -ne 0 ]; then
	COLOR_NEXT="$COLOR_RED"
elif [ -z "$PI_SERIAL" ]; then
	COLOR_NEXT="$COLOR_RED"
fi	
echo "Serial Number: ${COLOR_NEXT}${PI_SERIAL}${COLOR_NO}"


echo -n "Testing Voltage..."

VOLTAGE_STATUS_HEX=`vcgencmd get_throttled | cut -f 2 -d x`
VOLTAGE_STATUS_DEC=$((16#$VOLTAGE_STATUS_HEX))
VOLTAGE_STATUS_PREV=$(((VOLTAGE_STATUS_DEC & 0x10000) != 0))
VOLTAGE_STATUS_CUR=$(((VOLTAGE_STATUS_DEC & 0x1) != 0))

if [ $VOLTAGE_STATUS_CUR -ne 0 ]; then
	echo "${COLOR_RED}LOW${COLOR_NO}"
elif [ $VOLTAGE_STATUS_PREV -ne 0 ]; then
	echo "${COLOR_RED}LOW PREV${COLOR_NO}"
else
	echo "${COLOR_GREEN}OK${COLOR_NO}"
fi

bin/cpuburn-a53 &

echo -n "Running GPU: "

(sleep 10 && pkill kmscube) &

kmscube > /dev/null 2>&1 || true

echo -n "Testing CPU..."
CPUBURN_THREADS=`ps -Af | grep cpuburn-a53 | wc -l`

if [ $CPUBURN_THREADS -eq 5 ]; then
	echo "${COLOR_GREEN}OK${COLOR_NO}"
else
	echo "${COLOR_RED}LOW $CPUBURN_THREADS${COLOR_NO}"
fi

pkill cpuburn-a53
trap - EXIT

echo -n "Testing HDMI..."
if [ "$PI_VER" = "4B" ]; then
	#HDMI_STATUS=`cat /sys/class/drm/card1/card1-HDMI-A-1/status`
	#HDMI_ENABLED=`cat /sys/class/drm/card1/card1-HDMI-A-1/enabled`
	HDMI_MODES_SYS_FILE=/sys/class/drm/card0/card0-HDMI-A-1/modes
	if [ ! -e "$HDMI_MODES_SYS_FILE" ]; then
		HDMI_MODES_SYS_FILE=/sys/class/drm/card1/card1-HDMI-A-1/modes
	fi
else
	#HDMI_STATUS=`cat /sys/class/drm/card0/card0-HDMI-A-1/status`
	#HDMI_ENABLED=`cat /sys/class/drm/card0/card0-HDMI-A-1/enabled`
	HDMI_MODES_SYS_FILE=/sys/class/drm/card0/card0-HDMI-A-1/modes
fi
if [ ! -e $HDMI_MODES_SYS_FILE ]; then
	echo "${COLOR_RED}NOT FOUND!${COLOR_NO}"
else
	if [ "$PI_VER" = "4B" ]; then
		HDMI_MODE_TARGET=`cat $HDMI_MODES_SYS_FILE | grep 3840x2160`
	else
		HDMI_MODE_TARGET=`cat $HDMI_MODES_SYS_FILE | grep 1920x1080`
	fi
	if [ -z "$HDMI_MODE_TARGET" ]; then
		echo "${COLOR_RED}LOW `head -n 1 $HDMI_MODE_SYS_FILE`${COLOR_NO}"
	else
		echo "${COLOR_GREEN}OK${COLOR_NO}"
	fi
fi

echo -n "Testing Ethernet"
ETH=""
for eth in /sys/class/net/e*; do
	ETH=$eth
done
ETH=${ETH##*/}
if [ -z "$ETH" ]; then
	echo "...${COLOR_RED}NOT FOUND!${COLOR_NO}"
else
	echo -n " $ETH..."
	nmcli device connect $ETH > /dev/null 2>&1 || true
	ETH_STATE=`cat /sys/class/net/e*/operstate`
	if [ "$ETH_STATE" = "up" ]; then
		if [ -z "$IPERF_PORT" ]; then
			IPERF_RESULT=`iperf -x CMSV -y C -c $IPERF_IP 2> /dev/null`
		else
			IPERF_RESULT=`iperf -x CMSV -y C -c $IPERF_IP -p $IPERF_PORT 2> /dev/null`
		fi
		IPERF_RESULT_SUCCESS=`echo "$IPERF_RESULT" | grep ^20 || true`
		if [ -z "$IPERF_RESULT_SUCCESS" ]; then
			echo "${COLOR_RED}IPERF FAILED${COLOR_NO}"
		else
			IPERF_SPEED=`echo "$IPERF_RESULT" | cut -f 9 -d ,`
			IPERF_SPEED=$((IPERF_SPEED/1024/1024))
			if [ $IPERF_SPEED -gt $IPERF_SPEED_LOW ]; then
				echo "${COLOR_GREEN}OK ${IPERF_SPEED}Mb${COLOR_NO}"
			else
				echo "${COLOR_RED}LOW ${IPERF_SPEED}Mb${COLOR_NO}"
			fi
		fi
	else
		ETH_LINK=`cat /sys/class/net/e*/carrier`
		if [ "$ETH_LINK" -eq 0 ]; then
			echo "${COLOR_RED}NO LINK${COLOR_NO}"
		else
			echo "${COLOR_RED}NO ASSIGNMENT${COLOR_NO}"
		fi
	fi
fi

echo -n "Testing WiFi Signal..."
#nmcli radio wifi on > /dev/null 2>&1 || true
WIFI_NETS="`nmcli device wifi list 2> /dev/null | grep "^\\*\?\s*$WIFI_NAME\s" || true`"
if [ -z "$WIFI_NETS" ]; then
	echo "${COLOR_RED}NO WIRELESS NET${COLOR_NO}"
else
	echo -n "${COLOR_GREEN}OK${COLOR_NO} "
	echo "$WIFI_NETS" | head -n 1 | tr -s ' ' | cut -d " " -f 3,5-
	echo -n "Testing WiFi..."
	nmcli connection show 2> /dev/null | grep -o "^$WIFI_NAME \([0-9]*\)\?" | sed "s/\\s\\+\$//" | xargs -rd "\n" nmcli connection delete id > /dev/null 2>&1 || true
	nmcli device wifi connect "$WIFI_NAME" password "$WIFI_PASS" > /dev/null 2>&1 || true
	WIFI_STATUS="`nmcli device show wlan0 2> /dev/null || true`"
	WIFI_STATE="`echo "$WIFI_STATUS" | grep "GENERAL.STATE:" | tr -s ' ' | cut -f 2 -d ' ' | grep ^100 || true`"
	#WIFI_CONNECTION="`echo "$WIFI_STATUS" | grep "GENERAL.CONNECTION:" | tr -s ' ' | cut -f 2- -d ' '`"
	if [ -z "$WIFI_STATE" ]; then
		echo "${COLOR_RED}NO WIRELESS CONNECTION${COLOR_NO}"
	else
		WIFI_IPV4="`echo "$WIFI_STATUS" | grep "IP4.ADDRESS" | tr -s ' ' | cut -f 2 -d ' '`"
		if [ ! -z "$ETH" ]; then
			nmcli device disconnect $ETH > /dev/null 2>&1 || true
		fi
		if [ -z "$IPERF_PORT" ]; then
			IPERF_WIRELESS_RESULT=`iperf -x CMSV -y C -c $IPERF_IP 2> /dev/null || true`
		else
			IPERF_WIRELESS_RESULT=`iperf -x CMSV -y C -c $IPERF_IP -p $IPERF_PORT 2> /dev/null || true`
		fi
		nmcli device disconnect wlan0 > /dev/null 2>&1 || true
		IPERF_WIRELESS_RESULT_SUCCESS=`echo "$IPERF_WIRELESS_RESULT" | grep ^20 || true`
		if [ -z "$IPERF_WIRELESS_RESULT_SUCCESS" ]; then
			echo "${COLOR_RED}IPERF FAILED${COLOR_NO}"
		else
			IPERF_WIRELESS_SPEED=`echo "$IPERF_WIRELESS_RESULT" | cut -f 9 -d ,`
			IPERF_WIRELESS_SPEED=$((IPERF_WIRELESS_SPEED/1024/1024))
			if [ $IPERF_WIRELESS_SPEED -gt $IPERF_WIRELESS_SPEED_LOW ]; then
				echo "${COLOR_GREEN}OK ${IPERF_WIRELESS_SPEED}Mb${COLOR_NO}"
			else
				echo "${COLOR_RED}LOW ${IPERF_WIRELESS_SPEED}Mb${COLOR_NO}"
			fi
		fi
	fi
	nmcli connection show 2> /dev/null | grep -o "^$WIFI_NAME \([0-9]*\)\?" | sed "s/\\s\\+\$//" | xargs -rd "\n" nmcli connection delete id > /dev/null 2>&1 || true
fi

if [ "$PI_VER" = "4B" ]; then
	echo -n "Testing USB Device 1..."
	if [ -b /dev/sda1 ]; then
		echo "${COLOR_GREEN}OK${COLOR_NO}"
	else
		echo "${COLOR_RED}NOT FOUND${COLOR_NO}"
	fi
	echo -n "Testing USB Device 2..."
	if [ -b /dev/sdb1 ]; then
		echo "${COLOR_GREEN}OK${COLOR_NO}"
	else
		echo "${COLOR_RED}NOT FOUND${COLOR_NO}"
	fi
fi

while true; do
	read -n 1 -p "Press s to shutdown. Press r to reboot. Press t to re-test. Press c to go to configuration." KEY
	echo -e "\b "
	KEY=${KEY,,}
	if [ "$KEY" = "s" ]; then
		shutdown -P now
	elif [ "$KEY" = "r" ]; then
		reboot
	elif [ "$KEY" = "t" ]; then
		break
	elif [ "$KEY" = "c" ]; then
		./config.sh
	fi
done


exit
echo "Testing CVBS"
echo "Testing GPIO"
echo "Testing PoE"
echo "Testing MIPI CSI"
echo "Testing MIPI DSI"
echo "Testing Display 2"


