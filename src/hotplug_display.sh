#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

unblank_display() {
	xset dpms force on
}

update_resolution() {
	local display="${1}"
	xrandr --output "${display}" --mode 1920x1080
}

main() {
	for disp in 'HDMI-1' 'HDMI-2'; do
		if xrandr --query | grep "${disp} connected" &>/dev/null; then
			update_resolution "${disp}"
			unblank_display
		fi
	done
}

# start it forked so the monitor is active
# this is needed because udev activates the monitor
# AFTER this script returns
main &
