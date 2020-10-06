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
#   pi-topOS default: 'vc4-fkms-v3d' driver
#   pi-topOS default: 'hdmi_force_hotplug:1=1'
#     ensured that HDMI1 (secondary) is 'first'
#     for pi-top display cable - used for touchscreen!
displays=('HDMI-1')

is_installed() {
	if [ "$(dpkg -l "$1" 2>/dev/null | tail -n 1 | cut -d ' ' -f 1)" != "ii" ]; then
		return 1
	else
		return 0
	fi
}

start_gesture_support() {
	if is_installed touchegg; then
		systemctl restart touchegg
	fi
}

unblank_display() {
	xset dpms force on
}

update_resolution() {
	local display="${1}"
	xrandr --output "${display}" --mode 1920x1080
}

main() {
	for disp in "${displays[@]}"; do
		if xrandr --query | grep -q "${disp} connected"; then
			start_gesture_support
			update_resolution "${disp}"
			unblank_display
			break
		fi
	done
}

# This script requires monitor to be active
# However, udev activates monitor AFTER this script returns
# Therefore, we fork it
main &
