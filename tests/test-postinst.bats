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
source "${FILE_TO_TEST}" configure

# Mocks
expected_asoundrc="${GIT_ROOT}/tests/mocks/expected_asoundrc.conf"
expected_dns_config="${GIT_ROOT}/tests/mocks/expected_cloudfare_dns_config.conf"

# Breadcrumbs
env_success_breadcrumb="/tmp/env-success"


RESOLV_CONF_HEAD_FILE="/tmp/resolv.conf.head.test"
export RESOLV_CONF_HEAD_FILE

remove_artefacts() {
  rm "${env_success_breadcrumb}" || true
  rm "$(find_home_directories)/.asoundrc" || true
  rm "$(find_home_directories)/.asoundrc.bak" || true
  rm "${RESOLV_CONF_HEAD_FILE}" || true
}

setup() {
  remove_artefacts
}

teardown() {
  remove_artefacts
}

# ---------------------------------------------------------------------------

find_home_directories() {
  echo "/tmp";
}
export -f find_home_directories

pt-notify-send() {
  [ $# -ge 2 ] || return
  echo "pt-notify-send $@"
}
export -f pt-notify-send

raspi-config() {
  [ $# = 5 ] || return 1
  [ $1 = "nonint" ] || return 1
  [ $2 = "set_config_var" ] || return 1
  [ $3 = "dtparam=audio" ] || return 1
  [ $4 = "on" ] || return 1
  [ $5 = "/boot/config.txt" ] || return 1
  return 0
}
export -f raspi-config

#########
# TESTS #
#########
@test "raspi-config is called with correct parameters" {
  touch "$(find_home_directories)/.asoundrc"
  run apply_audio_fix
  assert_success

  assert [ -f "$(find_home_directories)/.asoundrc" ]
  assert [ -f "$(find_home_directories)/.asoundrc.bak" ]
}

@test "apply_audio_fix backs up existing configuration" {
  touch "$(find_home_directories)/.asoundrc"
  run apply_audio_fix
  assert_success

  assert [ -f "$(find_home_directories)/.asoundrc" ]
  assert [ -f "$(find_home_directories)/.asoundrc.bak" ]
}

@test "apply_audio_fix creates configuration if one doesn't exist" {
  assert [ ! -f "$(find_home_directories)/.asoundrc" ]
  run apply_audio_fix
  assert_success

  assert [ ! -f "$(find_home_directories)/.asoundrc.bak" ]
  assert [ -f "$(find_home_directories)/.asoundrc" ]
}

@test "apply_audio_fix creates a properly formatted configuration file" {
  run apply_audio_fix
  assert_success

  assert [ -f "$(find_home_directories)/.asoundrc" ]
  assert diff -q "${expected_asoundrc}" "$(find_home_directories)/.asoundrc"
}

@test "apply_audio_fix notifies the user" {
  run apply_audio_fix
  assert_success

  assert_output "pt-notify-send --expire-time=0 --icon=dialog-warning Audio configuration updated Please restart to apply changes"
}

@test "apply_cloudflare_dns writes the DNS configuration to a file" {
  run apply_cloudflare_dns
  assert_success

  assert diff -q "${expected_dns_config}" "${RESOLV_CONF_HEAD_FILE}"
}

@test "check_for_updates fails if no display is detected" {
  pgrep() { echo ""; }
  export -f pgrep

  run check_for_updates
  assert_output "Unable to find a display"
}

@test "raspi-config successfully runs with correct parameters" {
  run apply_audio_fix
  assert_success
}

@test "raspi-config fails when run with incorrect parameters" {
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
}

@test "Active OS updater is checked for correctly" {
  systemctl() {
    # systemctl will return zero exit code if args are correct
    [ $# = 3 ] || return 1
    [ $1 = "is-active" ] || return 1
    [ $2 = "--quiet" ] || return 1
    [ $3 = "pt-os-updater" ] || return 1
    return 0
  }
  export -f systemctl

  # os_updater_is_running will return zero exit code if systemctl exit code is zero
  run os_updater_is_running
  assert_success
}

@test "check_for_updates_now correctly checks for updates (calls env with correct arguments)" {
  # do not sleep
  os_updater_is_running() {
    return 1
  }
  export -f os_updater_is_running
  env() {
    [ $# = 2 ] || return 1
    [ $1 = "DISPLAY=${display}" ] || return 1
    [ $2 = "/usr/lib/pt-os-updater/check-now" ] || return 1
    touch "${env_success_breadcrumb}"
    return 0
  }
  export -f env

  run check_for_updates_now
  assert [ -f "${env_success_breadcrumb}" ]
}
