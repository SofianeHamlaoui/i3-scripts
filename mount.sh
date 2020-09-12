#!/bin/bash

all="$(lsblk -rpo "label,name,type,size,mountpoint" | grep -v 'mmcblk1' | awk '$3=="part"{if($5==""){printf "%s: %s (%s)\n",$1,$2,$4}else{printf "%s: %s (%s, mounted)\n",$1,$2,$4}}')"

get_mountpoint(){ \
	echo "$(lsblk -rpo "name,type,mountpoint" | awk -v name="$1" '$1==name&&$2=="part"{printf $3}')"
}

is_mounted(){ \
	if [ -z "$(get_mountpoint "$1")" ]; then
		echo "0"
	else
		echo "1"
	fi
}

if [ -z "$all" ]; then
	notify-send "No device found."
	exit
fi

chosen=$(echo -e "$all" | rofi -dmenu -show run -lines 5 -opacity "85" -bw 0 -width 30 -padding 20 -i -p "select a device" | awk '{print $2}')

[ "$chosen" ] || exit

actions="eject\nopen"
if [ "$(is_mounted "$chosen")" -eq "1" ]; then
	actions="unmount\n${actions}"
else
	actions="mount\n${actions}"
fi

action=$(echo -e $actions | rofi -dmenu -show run -lines 5 -opacity "85" -bw 0 -width 30 -padding 20 -i -p "action on $chosen" | awk '{print $1}')

[ "$action" ] || exit

err=""
case "$action" in
	mount)
		err="$(udisksctl mount --no-user-interaction -b "$chosen" 2>&1 1>/dev/null)"
		;;
	unmount)
		err="$(udisksctl unmount --no-user-interaction -b "$chosen" 2>&1 1>/dev/null)"
		;;
	eject)
        udisksctl unmount --no-user-interaction -b "$chosen"
		err="$(udisksctl power-off --no-user-interaction -b "$chosen" 2>&1 1>/dev/null)"
		;;
	open)
		mp="$(get_mountpoint "$chosen")"
		if [ -z "$mp" ]; then
			err="$(udisksctl mount --no-user-interaction -b "$chosen" 2>&1 1>/dev/null)"
			if [ -z "$err" ]; then
				notify-send "${chosen} mounted"
			else
				notify-send "$err"
			fi
		fi
		thunar "$mp"
		;;
esac
if [ -z "$err" ]; then
	notify-send "${chosen} ${action}ed"
else
	notify-send "$err"
fi
