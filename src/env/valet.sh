# Laravel Valet, services run on the host like the local environment

function env_valet_available() {
  command -v valet &> /dev/null
}

function env_valet_detect() {
  env_valet_available
}

function env_valet_setup_prepare() {
  env_local_setup_prepare "$@" || return 1

  mage_info "Securing with Valet..."
  valet secure "$1"
}

# Echo a store entry for the .valet-env.php, commented out when the third argument is 'true'
function env_valet_store_entry() {
  local store_name="${1:-store}"
  local store_code="${2:-default}"
  local prefix=""

  if [[ "$3" == true ]]; then
    prefix="// "
  fi

  printf "\t%s'%s' => [\n" "$prefix" "$store_name"
  printf "\t%s\t'MAGE_RUN_CODE' => '%s',\n" "$prefix" "$store_code"
  printf "\t%s\t'MAGE_RUN_TYPE' => 'store',\n" "$prefix"
  printf "\t%s],\n" "$prefix"
}

# Prepare the .valet-env.php for multi store setups, and the driver that keeps assets fresh
function env_valet_setup_finish() {
  local name="$1"

  {
    printf '<?php declare(strict_types=1);\n\nreturn [\n'
    env_valet_store_entry "$name" "default"
    env_valet_store_entry "store-2" "default2" true
    printf '];\n'
  } > .valet-env.php

  env_valet_add_driver
}

# Valet serves static files without Cache-Control, so browsers keep stale assets
# in developer mode, this driver makes them revalidate. An existing driver is kept.
function env_valet_add_driver() {
  if [[ -e LocalValetDriver.php ]]; then
    mage_notice "A LocalValetDriver.php is already present, skipping"
    return
  fi

  local template
  template="$(mage_template_file "LocalValetDriver.php")"

  if [[ -z "$template" ]]; then
    mage_warn "Could not get the LocalValetDriver.php from ${MAGE_TEMPLATES_ARCHIVE}"
    return 1
  fi

  cp "$template" LocalValetDriver.php
  mage_check 0 "Added LocalValetDriver.php, so the browser revalidates static files"
}

function env_valet_nuke() {
  local name="$1"

  env_local_nuke "$@"

  valet unsecure "$name"
  mage_check 0 "Valet site '${name}' unsecured"

  if [[ -f .valet-env.php ]] && command -v php &> /dev/null; then
    local store
    local stores
    stores="$(php -r '$stores = include ".valet-env.php"; if (is_array($stores)) { echo implode(PHP_EOL, array_keys($stores)); }' 2> /dev/null)"

    for store in $stores; do
      if [[ "$store" != "$name" ]]; then
        valet unsecure "$store"
        valet unlink "$store"
        mage_check 0 "Valet store '${store}' unsecured and unlinked"
      fi
    done
  fi
}

# Valet serves a site by its name without the tld, which is also the key in .valet-env.php
function env_valet_add_store() {
  local domain="$1"
  local code="$2"
  local site="${domain%.${MAGE_DOMAIN}}"

  if [[ ! -f .valet-env.php ]]; then
    env_valet_setup_finish "$(basename "$PWD")"
  fi

  if grep -q "'${site}' *=>" .valet-env.php; then
    mage_notice "${site} is already in .valet-env.php"
  else
    {
      grep -v '^];' .valet-env.php
      env_valet_store_entry "$site" "$code"
      printf '];\n'
    } > .valet-env.php.tmp && mv .valet-env.php.tmp .valet-env.php
    mage_check 0 "Added ${site} to .valet-env.php"
  fi

  valet link "$site" && valet secure "$site"
}
