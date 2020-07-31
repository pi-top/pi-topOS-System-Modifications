# shellcheck source=tests/helpers/global_variables.bash
source "tests/helpers/global_variables.bash"

FILE_TO_TEST="${GIT_ROOT}/src/pt-os-mods.sh"
export FILE_TO_TEST

_remove_artefacts() {
	for spoofed_home_dir in ${spoofed_home_dirs:?}; do
		rm "${spoofed_home_dir}/.asoundrc" || true
		rm "${spoofed_home_dir}/.asoundrc.bak" || true
	done
	rm "${valid_systemctl_breadcrumb:?}" || true
	rm "${FIX_SOUND_BREADCRUMB}" || true
}

setup_file() {
	# Set up test directories for files
	for spoofed_home_dir in ${spoofed_home_dirs}; do
		mkdir -p "${spoofed_home_dir}"
	done

	_remove_artefacts
}

setup() {
	source "${FILE_TO_TEST}"

	load "helpers/mock_functions.bash"
	load "helpers/mock_variables.bash"
}

teardown() {
	_remove_artefacts
}
