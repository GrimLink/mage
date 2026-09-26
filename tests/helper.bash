MAGE_REPO="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

# Source mage without running it, with an empty config folder
function load_mage() {
  export XDG_CONFIG_HOME="${BATS_TEST_TMPDIR}/config"
  source "${MAGE_REPO}/src/mage.sh"
}

# Create the files that mark a folder as the Magento root
function make_magento_root() {
  mkdir -p "$1/bin" "$1/app/etc"
  touch "$1/bin/magento" "$1/app/etc/di.xml"
}

# Put stub binaries on a PATH that only holds the system folders
function use_stub_bins() {
  local stub_dir="${BATS_TEST_TMPDIR}/bin"
  local bin

  mkdir -p "$stub_dir"

  for bin in "$@"; do
    printf '#!/bin/sh\nexit 0\n' > "${stub_dir}/${bin}"
    chmod +x "${stub_dir}/${bin}"
  done

  PATH="${stub_dir}:/usr/bin:/bin"
}
