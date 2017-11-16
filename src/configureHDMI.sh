#!/bin/bash

tmpFile="/tmp/edid.dat"

configFile="/boot/config.txt"
config="$(cat $configFile)"

hdmiGroupLine="$(echo "$config" | grep "hdmi_group" | cut -d'=' -f2)"
hdmiGroup="$(echo "$hdmiGroupLine" | cut -d'=' -f2)"

hdmiModeLine="$(echo "$config" | grep "hdmi_mode" | cut -d'=' -f2)"
hdmiMode="$(echo "$hdmiModeLine" | cut -d'=' -f2)"

# Get EDID dump
tvservice -d $tmpFile &> /dev/null

edid_parse_1=$(parse-edid < $tmpFile 2> /dev/null)
vendor_name="$(echo "$edid_parse_1" | grep "VendorName" | cut -d\" -f2)"
display_size_w="$(echo "$edid_parse_1" | grep "DisplaySize" | cut -d' ' -f2)"
display_size_h="$(echo "$edid_parse_1" | grep "DisplaySize" | cut -d' ' -f3)"

actual_tvservice_state="$(tvservice -s)"
expected_tvservice_state="state 0x120006 [DVI DMT (81) RGB full 16:9], 1366x768 @ 60.00Hz, progressive"

screenSettingsUpdated=0
# If screen is pi-top resolution and dimensions, with IVO vendor
echo "Vendor Name: $vendor_name"
if [[ "$vendor_name" == "IVO" ]]; then
	echo -e "Checking if likely to be a pi-top screen...\c"
	if [[ "$expected_tvservice_state" == "$actual_tvservice_state" ]] && [[ "$display_size_w" == "290" ]] && [[ "$display_size_h" == "170" ]]; then
		echo -e "Yes. Checking if HDMI group and mode are correctly configured...\c"
		# Check if HDMI group 2 and mode 86
		if [[ $hdmiGroup != "2" ]] || [[ $hdmiMode != "86" ]]; then
			echo "No."
			echo -e "Configuring...\c"
			screenSettingsUpdated=1
			# Run screen fix
			if [[ $hdmiGroup != "" ]] || [[ ${hdmiGroupLine:0:1} != '#' ]]; then
				sudo sed -i "s/.*hdmi_group.*/hdmi_group=2/g" "$configFile"
			else
				echo "hdmi_group=2" | sudo tee --append "$configFile"
			fi

			if [[ $hdmiMode != "" ]] || [[ ${hdmiModeLine:0:1} != '#' ]]; then
				sudo sed -i "s/.*hdmi_mode.*/hdmi_mode=86/g" "$configFile"
			else
				echo "hdmi_mode=86" | sudo tee --append "$configFile"
			fi
			echo -e "Done."
		else
			echo "Yes - doing nothing."
		fi
	else
		echo "No - doing nothing."
	fi
elif [[ "$vendor_name" == "BOE" ]]; then
	echo -e "Checking if likely to be a pi-top screen...\c"
	if [[ "$expected_tvservice_state" == "$actual_tvservice_state" ]] && [[ "$display_size_w" == "290" ]] && [[ "$display_size_h" == "170" ]]; then
		echo "Yes."
		echo "Commenting out HDMI group and mode in config if not already."
		# If hdmi_group and hdmi_mode lines are not already commented out
		if [[ ${hdmiGroupLine:0:1} != '#' ]] || [[ ${hdmiModeLine:0:1} != '#' ]]; then
			# Comment out
			sudo sed -i '/![^#]/ s/\(^.*hdmi_group.*$\)/#\ \1/' "$configFile"
			sudo sed -i '/![^#]/ s/\(^.*hdmi_mode.*$\)/#\ \1/' "$configFile"
			screenSettingsUpdated=1
		fi
	else
		echo "No - doing nothing."
	fi
else
	echo "Unrecognised vendor - doing nothing."
fi

if [ $screenSettingsUpdated -eq 1 ]; then
	zenity --info --text="New screen configuration has been detected.\nPlease restart for updated configuration to take effect." --display=:0 &> /dev/null &
fi
