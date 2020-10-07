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
load "helpers/hotplug-display-hooks.bash"

#########
# TESTS #
#########

# xrandr --output "${display}" --mode 1920x1080
# xrandr --query | grep "${disp} connected"

@test "Hotplug:        unblanking calls xset correctly" {
  # Run
  run unblank_display
  # update_resolution
  # main

  # Verify
  assert_line --index 0 "xset: OK"
}

@test "Hotplug:        updating resolution calls xrandr correctly" {
  # Run
  run update_resolution "HDMI-1"

  # Verify
  assert_line --index 0 "xrandr set res - HDMI-1: OK"

  # Run
  run update_resolution "HDMI-2"

  # Verify
  assert_line --index 0 "xrandr set res - HDMI-2: OK"
}

@test "Hotplug:        functions run when xrandr declares display is connected" {
  # Set Up
  update_resolution() {
    echo "update_resolution - ${1}: OK"
  }

  unblank_display() {
    echo "unblank_display: OK"
  }

  runlevel_is_x11() {
    return 0
  }

  # Run
  run main

  # Verify
  assert_line --index 0 "update_resolution - HDMI-1: OK"
  assert_line --index 1 "unblank_display: OK"
}

@test "Hotplug:        touchegg notification is shown if it is installed and not enabled" {
  # Set Up
  is_installed() {
    return 0
  }

  gesture_support_is_enabled_on_startup() {
    return 1
  }

  ask_user_to_start_gesture_support() {
    echo "touchegg: OK"
  }

  # Run
  run handle_gesture_support

  # Verify
  assert_output "touchegg: OK"
}

@test "Hotplug:        touchegg notification is not shown if it is installed and enabled" {
  # Set Up
  is_installed() {
    return 0
  }

  gesture_support_is_enabled_on_startup() {
    return 0
  }

  ask_user_to_start_gesture_support() {
    echo "touchegg: OK"
  }

  # Run
  run handle_gesture_support

  # Verify
  refute_output "touchegg: OK"
}

@test "Hotplug:        touchegg notification is not shown if it is not installed" {
  # Set Up
  is_installed() {
    return 1
  }

  ask_user_to_start_gesture_support() {
    echo "touchegg: OK"
  }

  # Run
  run handle_gesture_support

  # Verify
  refute_output "touchegg: OK"
}
