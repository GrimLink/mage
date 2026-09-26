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

# Prepare the .valet-env.php for multi store setups
function env_valet_setup_finish() {
  local name="$1"

  {
    printf '<?php declare(strict_types=1);\n\nreturn [\n'
    env_valet_store_entry "$name" "default"
    env_valet_store_entry "store-2" "default2" true
    printf '];\n'
  } > .valet-env.php
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
