#!./Bash-Automated-Testing-System/bats-core/bin/bats

###############
# BOILERPLATE #
###############
GIT_ROOT="$(git rev-parse --show-toplevel)"

load 'Bash-Automated-Testing-System/bats-support/load'
load 'Bash-Automated-Testing-System/bats-assert/load'

##############
# SETUP CODE #
##############
FILE_TO_TEST="${GIT_ROOT}/debian/pt-os-mods.postinst"

# Mocks
expected_dns_config="${GIT_ROOT}/tests/mocks/expected_cloudfare_dns_config.conf"
spoofed_home_dir="/tmp"


# Breadcrumbs
valid_systemctl_breadcrumb="/tmp/valid_systemctl"

remove_artefacts() {
  rm "${spoofed_home_dir}/.asoundrc" || true
  rm "${spoofed_home_dir}/.asoundrc.bak" || true
  rm "${RESOLV_CONF_HEAD_FILE}" || true
  rm "${valid_systemctl_breadcrumb}" || true
}

setup() {
  # Include functions
  source "${FILE_TO_TEST}" configure

  # Spoof functions globally
  is_pi_top_os() {
    return 0
  }

  get_user_home_directories() {
    echo "${spoofed_home_dir}";
  }
  export -f get_user_home_directories

  pt-notify-send() {
    [ "${#}" = 4 ] || return 1
    [ "${1}" = "--expire-time=0" ] || return 1
    [ "${2}" = "--icon=dialog-warning" ] || return 1
    [ "${3}" = "Audio configuration updated" ] || return 1
    [ "${4}" = "Please restart to apply changes" ] || return 1
    echo "OK"
  }
  export -f pt-notify-send

  raspi-config() {
    if [[ "${#}" = 5 ]]; then
        [ "${1}" = "nonint" ] || return 1
        [ "${2}" = "set_config_var" ] || return 1
        [ "${3}" = "dtparam=audio" ] || return 1
        [ "${4}" = "on" ] || return 1
        [ "${5}" = "/boot/config.txt" ] || return 1
        return 0
    elif [[ "${#}" = 3 ]]; then
        [ "${1}" = "nonint" ] || return 1
        [ "${2}" = "do_audio" ] || return 1
        [ "${3}" = "9" ] || return 1
        return 0
    fi
    return 1
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

  RESOLV_CONF_HEAD_FILE="/tmp/resolv.conf.head.test"
  export RESOLV_CONF_HEAD_FILE

  # Clean up
  remove_artefacts
}

teardown() {
  # Clean up
  remove_artefacts
}

#########
# TESTS #
#########

#--------
# Version Check
#--------
@test "Version Check: applies all patches if new installation" {
  # Set Up
  apply_audio_fix() {
    echo "1"
  }
  export -f apply_audio_fix

  apply_cloudflare_dns() {
    echo "2"
  }
  export -f apply_cloudflare_dns

  attempt_check_for_updates() {
    echo "3"
  }
  export -f attempt_check_for_updates

  # Run
  run main

  # Verify
  assert_line "1"
  assert_line "2"
  assert_line "3"
}

@test "Version Check: patches are associated with correct versions" {
  # Set Up
  apply_audio_fix() { return; }
  export -f apply_audio_fix

  apply_cloudflare_dns() { return; }
  export -f apply_cloudflare_dns

  attempt_check_for_updates() { return; }
  export -f attempt_check_for_updates

  previous_version_requires_patch() {
    [ "${1}" = "6.3.0" ] && echo "Audio"
    [ "${1}" = "6.1.0" ] && echo "DNS"
    [ "${1}" = "6.0.1" ] && echo "Updates"
  }
  export -f previous_version_requires_patch

  # Run
  run main

  # Verify
  assert_line --index 0 "Audio"
  assert_line --index 1 "DNS"
  assert_line --index 2 "Updates"
}

#--------
# Audio Fix
#--------
@test "Audio Fix: backs up existing configuration" {
  # Set Up
  touch "$(get_user_home_directories)/.asoundrc"

  # Run
  run apply_audio_fix

  # Verify
  assert_success
  assert [ -f "$(get_user_home_directories)/.asoundrc.bak" ]
}

@test "Audio Fix: creates configuration if one doesn't exist" {  # Run
  run apply_audio_fix

  # Verify
  assert_success
  assert [ ! -f "$(get_user_home_directories)/.asoundrc.bak" ]
}

@test "Audio Fix: creates a properly formatted configuration file" {  # Run
  run apply_audio_fix
  # Verify
  assert_success
}

@test "Audio Fix: notifies the user" {  # Run
  run apply_audio_fix
  # Verify
  assert_success
  assert_output "OK"
}

@test "Audio Fix: sets default card number to 1 if Headphones isn't present in aplay" {
  # Set Up
  raspi-config() {
    if [[ "${#}" = 5 ]]; then
        [ "${1}" = "nonint" ] || return 1
        [ "${2}" = "set_config_var" ] || return 1
        [ "${3}" = "dtparam=audio" ] || return 1
        [ "${4}" = "on" ] || return 1
        [ "${5}" = "/boot/config.txt" ] || return 1
        return 0
    elif [[ "${#}" = 3 ]]; then
        [ "${1}" = "nonint" ] || return 1
        [ "${2}" = "do_audio" ] || return 1
        [ "${3}" = "1" ] || return 1
        return 0
    fi
    return 1
  }
  export -f raspi-config

  aplay() { return; }
  export -f aplay

  # Run
  run apply_audio_fix

  # Verify
  assert_success
}

@test "Audio Fix: calls raspi-config successfully with correct parameters" {  # Run
  run apply_audio_fix
  # Verify
  assert_success
}

@test "Audio Fix: raspi-config fails when run with incorrect parameters" {  # Run and verify all the things
  run raspi-config
  assert_failure

  run raspi-config wrong
  assert_failure

  run raspi-config wrong config
  assert_failure

  run raspi-config wrong config parameters
  assert_failure

  run raspi-config wrong config parameters here
  assert_failure

  run raspi-config nonint do_audio 0
  assert_failure
}

#--------
# Cloudflare DNS
#--------
@test "Cloudflare DNS: writes the DNS configuration to a file" {  # Run
  run apply_cloudflare_dns
  # Verify
  assert_success
  assert diff -q "${expected_dns_config}" "${RESOLV_CONF_HEAD_FILE}"
}

#--------
# Update Check
#--------
@test "Update Check: fails if no display is detected" {  # Set Up
  pgrep() { echo ""; }
  export -f pgrep

  # Run
  run attempt_check_for_updates
  # Verify
  assert_output "Unable to find a display"
}

@test "Update Check: checks for active OS updater correctly" {  # Set Up
  systemctl() {
    # systemctl will return zero exit code if args are correct
    if [ "${#}" = 3 ] && \
      [ "${1}" = "is-active" ] && \
      [ "${2}" = "--quiet" ] && \
      [ "${3}" = "pt-os-updater" ]; then
      touch "${valid_systemctl_breadcrumb}"
    fi
    # Do not sleep
    return 1
  }
  export -f systemctl

  # Run
  run do_update_check

  # Verify
  assert [ -f "${valid_systemctl_breadcrumb}" ]
}

@test "Update Check: correctly checks for updates (calls env with correct arguments)" {  # Set Up
  systemctl() {
    # Do not sleep
    return 1
  }
  export -f systemctl

  env() {
    [ "${#}" = 2 ] || return 1
    [ "${1}" = "DISPLAY=${display}" ] || return 1
    [ "${2}" = "/usr/lib/pt-os-updater/check-now" ] || return 1
    echo "OK"
    return 0
  }
  export -f env

  # Run
  run do_update_check

  # Verify
  assert_output "OK"
}
