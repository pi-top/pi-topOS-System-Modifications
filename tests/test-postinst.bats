#!./Bash-Automated-Testing-System/bats-core/bin/bats

###############
# BOILERPLATE #
###############
GIT_ROOT="$(git rev-parse --show-toplevel)"

load 'Bash-Automated-Testing-System/bats-support/load'
load 'Bash-Automated-Testing-System/bats-assert/load'

############################
# PRE- AND POST-TEST HOOKS #
############################
FILE_TO_TEST="${GIT_ROOT}/debian/pt-os-mods.postinst"

remove_artefacts() {
  for spoofed_home_dir in ${spoofed_home_dirs}; do
    rm "${spoofed_home_dir}/.asoundrc" || true
    rm "${spoofed_home_dir}/.asoundrc.bak" || true
  done
  rm "${RESOLV_CONF_HEAD_FILE}" || true
  rm "${valid_systemctl_breadcrumb}" || true
}

setup_file() {
  # Set up test directories for files
  for spoofed_home_dir in ${spoofed_home_dirs}; do
    mkdir -p "${spoofed_home_dir}"
  done

  # Clean up
  remove_artefacts
}

setup() {
  # Source test file
  source "${FILE_TO_TEST}" configure

  # Source global mocks
  load "mocks/mock_functions.bash"
  load "mocks/mock_variables.bash"
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
    echo "Applied audio fix"
  }
  export -f apply_audio_fix

  apply_cloudflare_dns() {
    echo "Applied Cloudflare DNS"
  }
  export -f apply_cloudflare_dns

  attempt_check_for_updates() {
    echo "Attempted to check for updates"
  }
  export -f attempt_check_for_updates

  previous_version_requires_patch() {
    return 0
  }
  export -f previous_version_requires_patch

  # Run
  run main

  # Verify
  assert_line --index 0 "Applied audio fix"
  assert_line --index 1 "Applied Cloudflare DNS"
  assert_line --index 2 "Attempted to check for updates"
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
  for home_dir in $(get_user_home_directories); do
    touch "${home_dir}/.asoundrc"
  done

  # Run
  run apply_audio_fix

  # Verify
  assert_success
  for home_dir in $(get_user_home_directories); do
    assert [ -f "${home_dir}/.asoundrc.bak" ]
  done
}

@test "Audio Fix: creates configuration if one doesn't exist" {
  # Run
  run apply_audio_fix

  # Verify
  assert_success
  for home_dir in $(get_user_home_directories); do
    assert [ ! -f "${home_dir}/.asoundrc.bak" ]
  done
}

@test "Audio Fix: creates a properly formatted configuration file" {
  # Run
  run apply_audio_fix
  # Verify
  assert_success
}

@test "Audio Fix: notifies the user" {
  # Run
  run apply_audio_fix

  # Verify
  assert_success
  assert_line --index 0 "env do_audio - SUDO_USER=root: OK"
  assert_line --index 1 "env do_audio - SUDO_USER=pi: OK"
  assert_line --index 2 "pt-notify-send: OK"
}

@test "Audio Fix: default card number to -1 if Headphones isn't present in aplay" {
  # Set Up
  aplay() { return; }
  export -f aplay

  # Run
  run get_headphones_alsa_card_number

  # Verify
  assert_output "-1"
}

@test "Audio Fix: raspi-config runs with correct parameters" {
  # Run and verify success conditions
  run raspi-config nonint set_config_var "dtparam=audio" "on" "/boot/config.txt"
  assert_success

  run apply_audio_fix
  assert_line --index 0 "env do_audio - SUDO_USER=root: OK"
  assert_line --index 1 "env do_audio - SUDO_USER=pi: OK"
}

@test "Audio Fix: raspi-config test function fails when run with incorrect parameters" {
  # Run and verify fail conditions
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
@test "Cloudflare DNS: writes the DNS configuration to a file" {
  # Run
  run apply_cloudflare_dns
  # Verify
  assert_success
  assert diff -q "${expected_dns_config}" "${RESOLV_CONF_HEAD_FILE}"
}

#--------
# Update Check
#--------
@test "Update Check: fails if no display is detected" {
  # Set Up
  get_display() { return; }
  export -f get_display

  # Run
  run attempt_check_for_updates
  # Verify
  assert_output "Unable to find a display"
}

@test "Update Check: checks for active OS updater correctly" {
  # Run
  run do_update_check

  # Verify
  assert [ -f "${valid_systemctl_breadcrumb}" ]
}

@test "Update Check: correctly checks for updates (calls env with correct arguments)" {
  # Run
  run do_update_check $(get_display)

  # Verify
  assert_output "env update check - DISPLAY=$(get_display): OK"
}
