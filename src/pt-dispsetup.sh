#!/bin/bash

display_name="HDMI-1"

force_mode_w="1920"
force_mode_h="1080"

main() {
  if graphics_stack_is_valid; then
    if display_has_been_connected; then
      # Do what arandr wanted to do originally
      /usr/share/dispsetup.sh
    else
      set_vnc_resolution_if_available
    fi
  fi
}

# Helper functions
graphics_stack_is_valid() {
  if grep -q okay /proc/device-tree/soc/v3d@7ec00000/status 2>/dev/null || grep -q okay /proc/device-tree/soc/firmwarekms@7e600000/status 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

display_has_been_connected() {
  edid_dump_file="/tmp/pt-dispsetup-test-edid-dump.dat"
  rm -f "${edid_dump_file}" || true
  if [[ $(tvservice -d "${edid_dump_file}") != *"Nothing written!"* ]]; then
    rm "${edid_dump_file}"
    return 0
  else
    return 1
  fi
}

set_vnc_resolution_if_available() {
  local force_mode_res="${force_mode_w}x${force_mode_h}_vnc"

  if xrandr --output "${display_name}" --mode "${force_mode_res}" --dryrun; then
    xrandr --output "${display_name}" --mode "${force_mode_res}"
  fi
}

main
exit 0
