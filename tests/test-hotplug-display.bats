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

  # Run
  run main

  # Verify
  assert_line --index 0 "update_resolution - HDMI-1: OK"
  assert_line --index 1 "unblank_display: OK"
}

@test "Hotplug:        touchegg is started if it isn't already running" {
  # Set Up
  pgrep() {
    return 1
  }

  # Run
  run start_gesture_support

  # Verify
  assert_output "touchegg: OK"
}

@test "Hotplug:        touchegg is not started if it is already running" {
  # Set Up
  pgrep() {
    echo "1234"  # spoofed PID
    return 0
  }

  # Run
  run start_gesture_support

  # Verify
  refute_output "touchegg: OK"
}
