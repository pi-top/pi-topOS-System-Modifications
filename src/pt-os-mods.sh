#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

is_pi_top_os() {
	if [[ -f "/etc/pt-issue" ]]; then
		return 0
	else
		return 1
	fi
}

get_users() {
	getent passwd | grep -wFf /etc/shells | awk -F':' '{print $1}'
}

get_home_directory_for_user() {
	local user="${1}"
	[[ -z "${user}" ]] && return
	getent passwd | grep -wFf /etc/shells | grep "${user}" | awk -F':' '{print $(NF-1)}'
}

get_alsa_card_number_by_name() {
	local card_to_lookup="${1}"
	# Find card number corresponding to card name; default to -1
	card_number=$(aplay -l | grep "${card_to_lookup}" | grep -o "card\\s[0-9]" | cut -d ' ' -f 2)
	echo "${card_number:--1}"
}

get_default_audio_card_for_device() {
	if aplay -l | grep -q snd_rpi_hifiberry_dac; then
		# Hifiberry found in list; use that
		echo "snd_rpi_hifiberry_dac"
	elif [[ $(pt-host) == "pi-top [3]" ]]; then
		# Support speaker over HDMI
		echo "bcm2835 HDMI 1"
	else
		# Audio jack, unless peripheral is detected by device manager
		echo "bcm2835 Headphones"
	fi
}

apply_audio_fix() {
	if ! aplay -l | grep -q snd_rpi_hifiberry_dac; then
		# Ensure 'dtparam=audio=on' is in /boot/config.txt
		raspi-config nonint set_config_var "dtparam=audio" "on" "/boot/config.txt"
	fi

	# Find default card number for device
	card_number=$(get_alsa_card_number_by_name "$(get_default_audio_card_for_device)")

	# For each user
	for user in $(get_users); do
		home_dir="$(get_home_directory_for_user "${user}")"
		asoundrc_file="${home_dir}/.asoundrc"

		# Back up existing asound configuration
		[[ -f "${asoundrc_file}" ]] && mv "${asoundrc_file}" "${asoundrc_file}.bak"

		# Set audio card to headphones
		env SUDO_USER="${user}" raspi-config nonint do_audio "${card_number}"

		# Fix file permissions
		chown "${user}:${user}" "${asoundrc_file}"
	done

	# Notify user using display that a restart is required
	pt-notify-send \
		--expire-time=0 \
		--icon=dialog-warning \
		"Sound configuration updated" \
		"Please restart to apply changes.
You may experience sound issues until you do." \
		--action=Restart:'env SUDO_ASKPASS=/usr/lib/pt-os-mods/pwdptom.sh sudo -A /sbin/reboot'
}

system_using_new_alsa_config() {
	if aplay -l | grep -q "bcm2835 ALSA"; then
		# Old implementation
		return 1
	else
		return 0
	fi
}

FIX_SOUND_BREADCRUMB="/etc/pi-top/.configuredDefaultAlsaOutput"
main() {
	# Run fix only once
	[[ -f "${FIX_SOUND_BREADCRUMB}" ]] &&
		echo "Fix already applied - doing nothing..." &&
		return

	if ! system_using_new_alsa_config; then
		echo "System not using new ALSA config - doing nothing..."
		return
	fi

	apply_audio_fix
	touch "${FIX_SOUND_BREADCRUMB}"
}

if is_pi_top_os; then
	main
fi
