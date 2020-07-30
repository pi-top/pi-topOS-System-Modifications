# shellcheck source=tests/helpers/global_variables.bash
source "tests/helpers/global_variables.bash"

FILE_TO_TEST="${GIT_ROOT}/debian/pt-os-mods.postinst"
export FILE_TO_TEST

_remove_artefacts() {
	rm "${RESOLV_CONF_HEAD_FILE}" || true
	rm "${valid_systemctl_breadcrumb:?}" || true
}

setup_file() {
	_remove_artefacts
}

setup() {
	# shellcheck source=debian/pt-os-mods.postinst
	source "${FILE_TO_TEST}" configure

	load "helpers/mock_functions.bash"
	load "helpers/mock_variables.bash"
}

teardown() {
	_remove_artefacts
}
