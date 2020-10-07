#!/bin/bash

# Touchscreen only compatible with pi-top [4]
# Therefore, only compatible with Raspberry Pi 4
#   pi-topOS default: 'vc4-fkms-v3d' driver
#   pi-topOS default: 'hdmi_force_hotplug:1=1'
#     ensured that HDMI1 (secondary) is 'first'
#     for pi-top display cable - used for touchscreen!
displays=('HDMI-1')

is_installed() {
	if [ "$(dpkg -l "$1" 2>/dev/null | tail -n 1 | cut -d ' ' -f 1)" == "ii" ]; then
		return 0
	else
		return 1
	fi
}

runlevel_is_x11() {
	if [[ $(runlevel | awk '{print $NF}') -eq 5 ]]; then
		return 0
	else
		return 1
	fi
}

enable_gesture_support() {
	if is_installed touchegg; then
		systemctl enable touchegg
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
	# Touchscreen interface triggered this udev rule
	# So we want to enable the service for the future
	enable_gesture_support

	# Start the service now if possible, otherwise wait for systemd to start it
	if runlevel_is_x11; then
		# Start it now
		start_gesture_support
	else
		# Wait for graphical target runlevel
		while ! runlevel_is_x11; do
			sleep 1
		done
	fi

	# Update display state - may not be connected!
	for disp in "${displays[@]}"; do
		if xrandr --query | grep -q "${disp} connected"; then
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
