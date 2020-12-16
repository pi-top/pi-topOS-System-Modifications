## shellcheck disable=SC2096,SC2239
#!./Bash-Automated-Testing-System/bats-core/bin/bats

###############
# BOILERPLATE #
###############
# shellcheck disable=SC2034
GIT_ROOT="$(git rev-parse --show-toplevel)"

load "Bash-Automated-Testing-System/bats-support/load"
load "Bash-Automated-Testing-System/bats-assert/load"

###############
# SETUP/HOOKS #
###############
load "helpers/global_variables.bash"
load "helpers/postinst-hooks.bash"

#########
# TESTS #
#########

#--------
# Version Check
#--------
@test "Version Check:  applies all patches if new installation" {
  # Set Up
  notify_user_to_reboot_for_audio_update() {
    echo "Notified user"
  }

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
  assert_line --index 0 "Notified user"
  assert_line --index 1 "Applied Cloudflare DNS"
  assert_line --index 2 "Attempted to check for updates"
}

@test "Version Check:  patches are associated with correct versions" {
  # Set Up
  apply_cloudflare_dns() { return; }
  export -f apply_cloudflare_dns

  attempt_check_for_updates() { return; }
  export -f attempt_check_for_updates

  previous_version_requires_patch() {
    [[ "${1}" == "6.1.0" ]] && echo "DNS"
    [[ "${1}" == "6.0.1" ]] && echo "Updates"
  }
  export -f previous_version_requires_patch

  # Run
  run main

  # Verify
  assert_line --index 0 "DNS"
  assert_line --index 1 "Updates"
}

@test "Version Check:  checks versions to apply patches properly" {
  if ! command -v dpkg; then
    skip "dpkg not installed"
  fi

  previous_version=""
  export previous_version
  run previous_version_requires_patch "1.0.0"
  assert_success

  previous_version="1.0.0"
  export previous_version
  run previous_version_requires_patch "2.0.0"
  assert_success

  previous_version="4.0.0"
  export previous_version
  run previous_version_requires_patch "3.0.0"
  assert_failure

  previous_version="4.0.0"
  export previous_version
  run previous_version_requires_patch "4.0.0"
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
  # shellcheck disable=SC2154
  assert diff -q "${expected_dns_config}" "${RESOLV_CONF_HEAD_FILE}"
}

#--------
# Update Check
#--------
@test "Update Check:   fails if no display is detected" {
  # Set Up
  get_display() { return; }
  export -f get_display

  # Run
  run attempt_check_for_updates
  # Verify
  assert_line --index 0 "Attempting to check for updates"
  assert_line --index 1 "Unable to find a display"
}

@test "Update Check:   checks for active OS updater correctly" {
  # Run
  run do_update_check

  # Verify
  # shellcheck disable=SC2154
  assert [ -f "${valid_systemctl_breadcrumb}" ]
}

@test "Update Check:   correctly checks for updates (calls env with correct arguments)" {
  # Run
  run do_update_check "$(get_display)"

  # Verify
  assert_line --index 0 "Checking updates"
  assert_line --index 1 "env update check - DISPLAY=$(get_display): OK"
}
