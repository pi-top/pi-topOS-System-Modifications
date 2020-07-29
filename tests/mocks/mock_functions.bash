# Mocks
spoofed_home_dirs="/tmp/test/root
/tmp/test/home/pi"
spoofed_users="root
pi"

# Breadcrumbs
valid_systemctl_breadcrumb="/tmp/valid_systemctl"

is_pi_top_os() {
	return 0
}

get_user_home_directories() {
	echo "${spoofed_home_dirs}"
}
export -f get_user_home_directories

get_users() {
	echo "${spoofed_users}"
}
export -f get_users

pt-notify-send() {
	[ "${#}" = 4 ] || return 1
	[ "${1}" = "--expire-time=0" ] || return 1
	[ "${2}" = "--icon=dialog-warning" ] || return 1
	[ "${3}" = "Audio configuration updated" ] || return 1
	[ "${4}" = "Please restart to apply changes" ] || return 1
	echo "pt-notify-send: OK"
}
export -f pt-notify-send

systemctl() {
	# systemctl will return zero exit code if args are correct
	if [ "${#}" = 3 ] &&
		[ "${1}" = "is-active" ] &&
		[ "${2}" = "--quiet" ] &&
		[ "${3}" = "pt-os-updater" ]; then
		touch "${valid_systemctl_breadcrumb}"
	fi
	# Do not sleep
	return 1
}
export -f systemctl

get_display() {
	echo ":0"
}
export -f get_display

env() {
	if [[ "${#}" = 2 ]]; then
		[ "${1}" = "DISPLAY=$(get_display)" ] || return 1
		[ "${2}" = "/usr/lib/pt-os-updater/check-now" ] || return 1
		echo "env update check - $1: OK"

		return 0
	elif [[ "${#}" = 5 ]]; then
		[ "${1}" = "SUDO_USER=root" ] || [ "${1}" = "SUDO_USER=pi" ] || return 1
		[ "${2}" = "raspi-config" ] || return 1
		[ "${3}" = "nonint" ] || return 1
		[ "${4}" = "do_audio" ] || return 1
		[ "${5}" = "$(get_headphones_alsa_card_number)" ] || return 1
		echo "env do_audio - $1: OK"
		return 0
	else
		return 1
	fi
}

raspi-config() {
	[ "${#}" = 5 ] || return 1
	[ "${1}" = "nonint" ] || return 1
	[ "${2}" = "set_config_var" ] || return 1
	[ "${3}" = "dtparam=audio" ] || return 1
	[ "${4}" = "on" ] || return 1
	[ "${5}" = "/boot/config.txt" ] || return 1
	return 0
}
export -f raspi-config

aplay() {
	echo "**** List of PLAYBACK Hardware Devices ****
card 0: b1 [bcm2835 HDMI 1], device 0: bcm2835 HDMI 1 [bcm2835 HDMI 1]
  Subdevices: 4/4
  Subdevice \#0: subdevice \#0
  Subdevice \#1: subdevice \#1
  Subdevice \#2: subdevice \#2
  Subdevice \#3: subdevice \#3
card 9: Headphones [bcm2835 Headphones], device 0: bcm2835 Headphones [bcm2835 Headphones]
  Subdevices: 4/4
  Subdevice \#0: subdevice \#0
  Subdevice \#1: subdevice \#1
  Subdevice \#2: subdevice \#2
  Subdevice \#3: subdevice \#3
"
}
export -f aplay
