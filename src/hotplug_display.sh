#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

# Touchscreen only compatible with pi-top [4]
# Therefore, only compatible with Raspberry Pi 4
# Therefore, only need to look at possible display names
displays=('HDMI-1' 'HDMI-2')

unblank_display() {
	xset dpms force on
}

update_resolution() {
	local display="${1}"
	xrandr --output "${display}" --mode 1920x1080
}

main() {
	for disp in "${displays[@]}"; do
		if xrandr --query | grep "${disp} connected" &>/dev/null; then
			update_resolution "${disp}"
			unblank_display
		fi
	done
}

# This script requires monitor to be active
# However, udev activates monitor AFTER this script returns
# Therefore, we fork it
main &
