#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

udev_breadcrumb="/tmp/pt-hotplug-display.breadcrumb"

wait_for_file_to_exist() {
	local path="${1}"

	# If file already exists, continue immediately
	[[ -f ${path} ]] && return

	local dir
	dir="$(dirname "${path}")"
	local file
	file="$(basename "${path}")"
	while read -r i; do if [ "$i" = "${file}" ]; then break; fi; done \
		< <(inotifywait -e create,open --format '%f' --quiet "${dir}" --monitor)
}

package_is_installed() {
	if [ "$(dpkg -l "$1" 2>/dev/null | tail -n 1 | cut -d ' ' -f 1)" == "ii" ]; then
		return 0
	else
		return 1
	fi
}

get_touchegg_start_command() {
	if package_is_installed pt-ui-mods; then
		echo "pt-touchegg"
	else
		echo "systemctl --user start touchegg"
	fi
}

get_user_using_display() {
	# TODO: rename pt-display; move to low-level tools package
	# TODO: add `-u` flag to get user only and avoid grepping
	pt-display | grep "User currently using display" | cut -d$'\t' -f2
}

run_systemd_command_as_user() {
	local user="${1}"
	local command="${2}"

	local id
	id="$(id -u "${user}")"
	local args="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${id}/bus"

	sudo -u "${user}" "${args}" "${command}"
}

gesture_support_is_enabled_on_startup() {
	local user="${1}"
	if [[ "$(run_systemd_command_as_user "${user}" "systemctl --user is-enabled touchegg")" == "enabled" ]]; then
		return 0
	else
		return 1
	fi
}

ask_user_to_start_gesture_support() {
	title="pi-top Touchscreen Detected"

	if package_is_installed pt-notifications; then
		notify_send_command="pt-notify-send"
		timeout=0
		body="Would you like to start multi-touch gesture support? This will enable functionality such as using 2 fingers to right-click in most applications."

		# TODO: "Always Run" --> "Always Start When Touchscreen Is Connected"; leave and check breadcrumb in home dir
		now_action="--action=\"Start Now:${touchegg_start_command}\""
		always_action="--action=\"Always Run:${touchegg_enable_command}; ${touchegg_start_command}\""
	else
		notify_send_command="notify-send"
		timeout=10000
		body="Run Touchégg from the start menu to start gesture support"
	fi

	command="${notify_send_command} -i libinput-gestures -t ${timeout}"
	if [[ -n "${now_action}" ]]; then
		command="${command} ${now_action}"
	fi
	if [[ -n "${always_action}" ]]; then
		command="${command} ${always_action}"
	fi

	eval "${command} \"${title}\" \"${body}\""
}

start_gesture_support() {
	local user="${1}"
	run_systemd_command_as_user "${user}" "${touchegg_start_command}"
}

handle_gesture_support() {
	if ! package_is_installed touchegg; then
		echo "Package 'touchegg' is not installed - unable to handle gesture support"
		return 1
	fi

	local user
	user=$(get_user_using_display)
	if [[ -z "${user}" ]]; then
		echo "Unable to determine user using current display - skipping gesture support"
		return 1
	fi

	if ! gesture_support_is_enabled_on_startup "${user}"; then
		if package_is_installed libnotify-bin; then
			ask_user_to_start_gesture_support
		else
			echo "No binary which sends notifications to notification daemon found - cannot ask user to start gesture support"
			start_gesture_support "${user}"
		fi
	fi
}

update_resolution() {
	local display="${1}"
	xrandr --output "${display}" --mode 1920x1080
}

unblank_display() {
	xset dpms force on
}

handle_display_state() {
	# Touchscreen only compatible with pi-top [4]
	# Therefore, only compatible with Raspberry Pi 4
	#   pi-topOS default: 'vc4-fkms-v3d' driver
	#   pi-topOS default: 'hdmi_force_hotplug:1=1'
	#     ensured that HDMI1 (secondary) is 'first'
	#     for pi-top display cable - used for touchscreen!
	displays=('HDMI-1')

	# Update display state - may not be connected!
	for disp in "${displays[@]}"; do
		if xrandr --query | grep -q "${disp} connected"; then
			update_resolution "${disp}"
			unblank_display
			break
		fi
	done
}

main() {
	while true; do
		wait_for_file_to_exist "${udev_breadcrumb}"
		rm "${udev_breadcrumb}"

		handle_display_state

		handle_gesture_support
	done
}

touchegg_enable_command="systemctl --user enable touchegg"
touchegg_start_command="$(get_touchegg_start_command)"

main
