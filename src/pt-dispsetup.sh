#!/bin/sh

display_name="HDMI-1"

force_mode_w="1920"
force_mode_h="1080"


main() {
	remove_default_arandr_autostart_if_exists
	if graphics_stack_is_valid; then
		if display_is_connected; then
			# Do what arandr wanted to do originally
			/usr/share/dispsetup.sh
		else
			add_and_set_forced_resolution
		fi
	fi
}

# Helper functions
remove_default_arandr_autostart_if_exists() {
	default_arandr_autostart_file="/etc/xdg/autostart/arandr-autostart.desktop"
	if [ -f "${default_arandr_autostart_file}" ]; then
		rm "${default_arandr_autostart_file}"
	fi
}

graphics_stack_is_valid() {
	if grep -q okay /proc/device-tree/soc/v3d@7ec00000/status 2> /dev/null || grep -q okay /proc/device-tree/soc/firmwarekms@7e600000/status 2> /dev/null ; then
		return 0
	else
		return 1
	fi
}

display_is_connected() {
	if tvservice -d "${edid_dump_file}"; then
		rm "${edid_dump_file}"
		return 0
	else
		return 1
	fi
}

add_and_set_forced_resolution() {
	# Better to determine these dynamically...

	local force_mode_clk_mhz="173.00"

	local force_mode_flags="-hsync +vsync"

	local force_mode_hsync_start=2048
	local force_mode_hsync_end=2248
	local force_mode_hsync_total=2576

	local force_mode_vsync_start=1083
	local force_mode_vsync_end=1088
	local force_mode_vsync_total=1120

	local force_mode_res="${force_mode_w}x${force_mode_h}"

	# If desired resolution not available
	if ! xrandr --output "${display_name}" --mode "${force_mode_res}" --dryrun &> /dev/null; then 

		# Add desired resolution
		xrandr --newmode "${force_mode_res}" "${force_mode_clk_mhz}" \
			"${force_mode_w}" "${force_mode_hsync_start}" "${force_mode_hsync_end}" "${force_mode_hsync_total}" \
			"${force_mode_h}" "${force_mode_vsync_start}" "${force_mode_vsync_end}" "${force_mode_vsync_total}" \
			"${force_mode_flags}"
		xrandr --addmode "${display_name}" "${force_mode_res}"
	fi

	# Set resolution to desired resolution
	xrandr --output "${display_name}" --mode "${force_mode_res}"
}

main
exit 0
