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
}
export -f pt-notify-send

pgrep() {
  [ $1 = "-a" ] || return
  [ $2 = "Xorg" ] || return
  echo "834 /usr/lib/xorg/Xorg :0 -seat seat0 -auth /var/run/lightdm/root/:0 -nolisten tcp vt7 -novtswitch"
}
export -f pgrep

#########
# TESTS #
#########
# Apply audio fix and notify user
# Apply Cloudflare DNS
# Check for updates again (with new apt key)

@test "apply_audio_fix finds the correct display number" {
  source "${FILE_TO_TEST}"
  run apply_audio_fix
  [ "$status" -eq 1 ]
  [ "$output" = "foo: no such file 'nonexistent_filename'" ]
  # assert_equal "$(get_display)" ":0"
}

@test "get_user_using_display finds user when display exists" {
  source "${FILE_TO_TEST}"
  local display=$(get_display)
  assert_equal "$(get_user_using_display "${display}")" "pi"
}

@test "get_user_using_display returns empty is display is not found" {
  source "${FILE_TO_TEST}"
  assert_equal "$(get_user_using_display ::1)" ""
}

@test "send_notification receives arguments correctly" {
  source "${FILE_TO_TEST}"

  function send_notification() {
    [ $1 = "pi" ] || echo "1st argument not 'pi'"
    [ $2 = ":0" ] || echo "2nd argument not ':0'"
    [ $3 = "message" ] || echo "3rd argument not 'message'"
    echo "Message sent"
  }
  export -f send_notification

  assert_equal "$(run_main message)" "Message sent"
}
