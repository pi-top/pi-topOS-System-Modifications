#!./Bash-Automated-Testing-System/bats-core/bin/bats

###############
# BOILERPLATE #
###############
GIT_ROOT="$(git rev-parse --show-toplevel)"

load "Bash-Automated-Testing-System/bats-support/load"
load "Bash-Automated-Testing-System/bats-assert/load"

###############
# SETUP/HOOKS #
###############
load "helpers/global_variables.bash"
load "helpers/systemd-service-hooks.bash"

#########
# TESTS #
#########

#--------
# Set Default Sound Card
#--------
@test "Set Default Sound Card:      backs up existing configuration" {
  # Set Up
  for user in $(get_users); do
    home_dir="$(get_home_directory_for_user "${user}")"
    touch "${home_dir}/.asoundrc"
  done

  # Run
  run apply_audio_fix

  # Verify
  assert_success
  for user in $(get_users); do
    home_dir="$(get_home_directory_for_user "${user}")"
    assert [ -f "${home_dir}/.asoundrc.bak" ]
  done

}

@test "Set Default Sound Card:      creates configuration if one doesn't exist" {
  # Run
  run apply_audio_fix

  # Verify
  assert_success
  for user in $(get_users); do
    home_dir="$(get_home_directory_for_user "${user}")"
    assert [ ! -f "${home_dir}/.asoundrc.bak" ]
  done
}

@test "Set Default Sound Card:      creates a properly formatted configuration file" {
  # Run
  run apply_audio_fix
  # Verify
  assert_success
}

@test "Set Default Sound Card:      notifies the user" {
  # Run
  run apply_audio_fix

  # Verify
  echo "${output}"
  assert_success
  assert_line --index 0 "env do_audio - SUDO_USER=root: OK"
  assert_line --index 1 "env do_audio - SUDO_USER=pi: OK"
  assert_line --index 2 "pt-notify-send: OK"
}

@test "Set Default Sound Card:      default card number to -1 if Headphones isn't present in aplay" {
  # Set Up
  aplay() { return; }

  # Run
  run get_alsa_card_number_by_name "bcm2835 Headphones"

  # Verify
  assert_output "-1"
}

@test "Set Default Sound Card:      raspi-config runs with correct parameters" {
  # Run and verify success conditions
  run raspi-config nonint set_config_var "dtparam=audio" "on" "/boot/config.txt"
  assert_success

  run apply_audio_fix
  assert_line --index 0 "env do_audio - SUDO_USER=root: OK"
  assert_line --index 1 "env do_audio - SUDO_USER=pi: OK"
}

@test "Set Default Sound Card:      raspi-config test function fails when run with incorrect parameters" {
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

@test "Set Default Sound Card:      gets the correct default sound card per pi-top device" {
  pt-host() { echo "pi-top [4]"; }

  run get_default_audio_card_for_device
  assert_output "bcm2835 Headphones"

  pt-host() { echo "pi-top [3]"; }

  run get_default_audio_card_for_device
  assert_output "bcm2835 HDMI 1"

  pt-host() { echo "any"; }

  run get_default_audio_card_for_device
  assert_output "bcm2835 Headphones"

  aplay() { echo "snd_rpi_hifiberry_dac"; }

  run get_default_audio_card_for_device
  assert_output "snd_rpi_hifiberry_dac"
}

@test "Set Default Sound Card:      gets the correct default sound card number per pi-top device" {
  pt-host() { echo "pi-top [4]"; }

  run get_alsa_card_number_by_name "$(get_default_audio_card_for_device)"
  assert_output 9

  pt-host() { echo "pi-top [3]"; }

  run get_alsa_card_number_by_name "$(get_default_audio_card_for_device)"
  assert_output 0

  pt-host() { echo "any"; }

  run get_alsa_card_number_by_name "$(get_default_audio_card_for_device)"
  assert_output 9
}

@test "Set Default Sound Card:      audio fix is applied if aplay output shows new version" {
  # Set Up
  apply_audio_fix() {
    echo "Applied audio fix"
  }

  run main
  assert_line --index 0 "Applied audio fix"
}

@test "Set Default Sound Card:      audio fix is not applied if aplay output shows old version" {
  system_using_new_alsa_config() {
    # System's alsa config is old
    return 1
  }

  run main
  assert_line --index 0 "System not using new ALSA config - doing nothing..."
}

@test "Set Default Sound Card:      main runs apply audio fix if breadcrumb doesnt exist" {
  # Set Up
  apply_audio_fix() {
    echo "Applied audio fix"
  }

  run main
  assert_line --index 0 "Applied audio fix"
}

@test "Set Default Sound Card:      main creates a breadcrumb if it doesn't exist" {
  # Set Up
  apply_audio_fix() { return ; }
  systemctl() { return ; }

  run main
  assert [ -f "${FIX_SOUND_BREADCRUMB}" ]
}

@test "Set Default Sound Card:      main does nothing if breadcrumb exists" {
  # Set Up
  touch "${FIX_SOUND_BREADCRUMB}"

  run main
  assert_output "Fix already applied - doing nothing..."
}
