#!/bin/bash
export TEXTDOMAIN=pt-os-mods

# shellcheck disable=SC1091
. gettext.sh

zenity --password --title "$(gettext "Password Required")"
