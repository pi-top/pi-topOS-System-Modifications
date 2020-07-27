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

main() {
  local previous_version="${1}"
  bash "${FILE_TO_TEST}" configure "${previous_version}"
}

raspi-config() {
  [ $# = 5 ] || return
  [ $1 = "nonint" ] || return
  [ $2 = "set_config_var" ] || return
  [ $3 = "dtparam=audio" ] || return
  [ $4 = "on" ] || return
  [ $5 = "/boot/config.txt" ] || return
}
export -f raspi-config

pt-notify-send() {
  [ $# -ge 2 ] || return
  echo "pt-notify-send $@"
}
export -f pt-notify-send


#########
# TESTS #
#########

@test "apply_audio_fix backs up existing configuration" {
  source "${FILE_TO_TEST}" configure
  find_home_directories() { echo "/tmp"; }
  export -f find_home_directories
  export -f raspi-config

  touch "$(find_home_directories)/.asoundrc"
  run apply_audio_fix
  assert_success

  assert [ -f "$(find_home_directories)/.asoundrc" ]
  rm "$(find_home_directories)/.asoundrc"
  assert [ -f "$(find_home_directories)/.asoundrc.bak" ]
  rm "$(find_home_directories)/.asoundrc.bak"
}

@test "apply_audio_fix creates configuration if one doesn't exist" {
  source "${FILE_TO_TEST}" configure
  find_home_directories() { echo "/tmp"; }
  export -f find_home_directories

  assert [ ! -f "$(find_home_directories)/.asoundrc" ]
  run apply_audio_fix
  assert_success

  assert [ ! -f "$(find_home_directories)/.asoundrc.bak" ]
  assert [ -f "$(find_home_directories)/.asoundrc" ]
  rm "$(find_home_directories)/.asoundrc"
}

@test "apply_audio_fix creates a properly formatted configuration file" {
  source "${FILE_TO_TEST}" configure
  find_home_directories() { echo "/tmp"; }
  export -f find_home_directories

  run apply_audio_fix
  assert_success

  assert [ -f "$(find_home_directories)/.asoundrc" ]
  expected_asoundrc="${GIT_ROOT}/tests/expected_asoundrc.conf"
  assert diff -q "${expected_asoundrc}" "$(find_home_directories)/.asoundrc"
  rm "$(find_home_directories)/.asoundrc"
}

@test "apply_audio_fix notifies the user" {
  source "${FILE_TO_TEST}" configure
  find_home_directories() { echo "/tmp"; }
  export -f find_home_directories

  run apply_audio_fix
  assert_success

  assert_output "pt-notify-send --expire-time=0 --icon=dialog-warning Audio configuration updated Please restart to apply changes"
  rm "$(find_home_directories)/.asoundrc"
}

@test "apply_cloudflare_dns writes the DNS configuration to a file" {
  source "${FILE_TO_TEST}" configure
  RESOLV_CONF_HEAD_FILE="/tmp/resolv.conf.head.test"
  export RESOLV_CONF_HEAD_FILE

  run apply_cloudflare_dns
  assert_success

  expected_dns_config="${GIT_ROOT}/tests/expected_cloudfare_dns_config.conf"
  assert diff -q "${expected_dns_config}" "${RESOLV_CONF_HEAD_FILE}"
  rm "${RESOLV_CONF_HEAD_FILE}"
}

@test "check_for_updates fails if no display is detected" {
  source "${FILE_TO_TEST}" configure
  pgrep() { echo ""; }
  export -f pgrep

  run check_for_updates
  assert_output "Unable to find a display"
}

@test "check_for_updates checks for updates on success" {
  source "${FILE_TO_TEST}" configure
  env() {
    [ $1 = "DISPLAY=:0" ] || return
    [ $2 = "/usr/lib/pt-os-updater/check-now" ] || return
  }
  export -f env

  run check_for_updates
  assert_success
}
