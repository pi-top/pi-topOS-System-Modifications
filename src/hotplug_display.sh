#!/bin/bash

IFS=$'\n\t'

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

handle_gesture_support() {
	if is_installed touchegg; then
		if ! gesture_support_is_enabled_on_startup; then
			ask_user_to_start_gesture_support
		fi
	fi
}

gesture_support_is_enabled_on_startup() {
	if [[ -f "/etc/xdg/autostart/touchegg.desktop" ]]; then
		return 0
	else
		return 1
	fi
}

system_has_notification_daemon() {
	dbus-send \
		--print-reply \
		--dest=org.freedesktop.DBus \
		/org/freedesktop/DBus org.freedesktop.DBus.ListNames |
		grep -q org.freedesktop.Notifications
}

ask_user_to_start_gesture_support() {
	if ! system_has_notification_daemon; then
		echo "No notification daemon - cannot ask user to start gesture support"
		return 1
	fi

	if is_installed pt-ui-mods; then
		touchegg_command="pt-touchegg"
	else
		touchegg_command="touchegg"
	fi
	if is_installed pt-notifications; then
		notify_send_command="pt-notify-send"
		timeout=0
		body="Would you like to start gesture support?"

		now_action="--action=\"Start Now:${touchegg_command}\""
		always_action="--action=\"Always Run:env SUDO_ASKPASS=/usr/lib/pt-os-mods/pwdptom.sh sudo -A cp /usr/share/applications/touchegg.desktop /etc/xdg/autostart/; ${touchegg_command}\""
	else
		notify_send_command="notify-send"
		timeout=10000
		body="Run Touchégg from the start menu to start gesture support"
	fi
	title="pi-top Touchscreen Detected"
	command="${notify_send_command} -i libinput-gestures -t ${timeout}"
	if [[ -n "${now_action}" ]]; then
		command="${command} ${now_action}"
	fi
	if [[ -n "${always_action}" ]]; then
		command="${command} ${always_action}"
	fi
	eval "${command} \"${title}\" \"${body}\""
}

unblank_display() {
	xset dpms force on
}

update_resolution() {
	local display="${1}"
	xrandr --output "${display}" --mode 1920x1080
}

main() {
	# Wait for graphical target runlevel
	while ! runlevel_is_x11; do
		sleep 1
	done

	handle_gesture_support

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
