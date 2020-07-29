# shellcheck disable=SC1091
source "tests/helpers/global_variables.bash"

_remove_artefacts() {
	for spoofed_home_dir in ${spoofed_home_dirs:?}; do
		rm "${spoofed_home_dir}/.asoundrc" || true
		rm "${spoofed_home_dir}/.asoundrc.bak" || true
	done
	rm "${RESOLV_CONF_HEAD_FILE}" || true
	rm "${valid_systemctl_breadcrumb:?}" || true
}

setup_file() {
	# Set up test directories for files
	for spoofed_home_dir in ${spoofed_home_dirs}; do
		mkdir -p "${spoofed_home_dir}"
	done

	# Clean up
	_remove_artefacts
}

setup() {
	# Source test file
	# shellcheck disable=SC1090
	source "${FILE_TO_TEST}" configure

	# Source globals
	load "helpers/mock_functions.bash"
	load "helpers/mock_variables.bash"
}

teardown() {
	# Clean up
	_remove_artefacts
}
