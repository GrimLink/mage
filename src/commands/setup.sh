# Install Magento in an existing project, optionally in the given folder
function mage_cmd_setup() {
  if [[ -n "$1" ]]; then
    if ! cd "$1" 2> /dev/null; then
      mage_error "Directory '$1' not found"
      exit 1
    fi
  fi

  mage_root_enter || exit 1
  mage_env_init

  local name
  name="$(basename "$PWD")"

  if [[ -f app/etc/env.php ]] && ! mage_confirm "This drops the database of '${name}' and installs Magento again, continue?"; then
    exit 0
  fi

  mage_setup "$name" || exit 1

  if [[ "$MAGE_CALL_DIR" == "$PWD" ]] || [[ "$MAGE_CALL_DIR" == "$PWD"/* ]]; then
    mage_getting_started "$name"
  else
    mage_getting_started "$name" true
  fi
}

# Run the Magento install with the MAGE_* settings of the current environment
function mage_setup() {
  local name="$1"
  local db_name="${MAGE_DB_NAME:-$name}"
  local url="https://${name}.${MAGE_DOMAIN}/"
  local admin_url="${name//-/}_admin"

  mage_system_user
  env_call setup_prepare "$name" "$db_name" || return 1

  mage_info "Running Magento setup install..."
  $MAGENTO_CLI setup:install \
    --backend-frontname="${admin_url}" \
    --base-url="${url}" \
    --use-rewrites=1 \
    --cleanup-database \
    --db-host="${MAGE_DB_HOST}" \
    --db-name="${db_name}" \
    --db-user="${MAGE_DB_USER}" \
    --db-password="${MAGE_DB_PASS}" \
    --search-engine=opensearch \
    --opensearch-host="${MAGE_SEARCH_HOST}" \
    --opensearch-port="${MAGE_SEARCH_PORT}" \
    --opensearch-index-prefix="${db_name}" \
    --opensearch-enable-auth=0 \
    --opensearch-timeout=15 \
    --session-save=redis \
    --session-save-redis-host="${MAGE_REDIS_HOST}" \
    --session-save-redis-db=2 \
    --session-save-redis-max-concurrency=20 \
    --cache-backend=redis \
    --cache-backend-redis-server="${MAGE_REDIS_HOST}" \
    --cache-backend-redis-db=0 \
    --cache-id-prefix="${db_name}_" \
    --page-cache=redis \
    --page-cache-redis-server="${MAGE_REDIS_HOST}" \
    --page-cache-redis-db=1 \
    --page-cache-id-prefix="${db_name}_" \
    --admin-firstname="${MAGE_ADMIN_FIRSTNAME}" \
    --admin-lastname="${MAGE_ADMIN_LASTNAME}" \
    --admin-email="${MAGE_ADMIN_EMAIL}" \
    --admin-user="${MAGE_ADMIN_USER}" \
    --admin-password="${MAGE_ADMIN_PASS}" || return 1

  mage_info "Setting default values for Store config"
  $MAGENTO_CLI config:set general/store_information/name "$name" &> /dev/null

  mage_set_store_config

  $MAGENTO_CLI deploy:mode:set developer

  mage_setup_disable_modules

  env_call setup_finish "$name"

  mage_clean_sample_files
  mage_add_gitignore
}

# Set the store config of MAGE_STORE_CONFIG, where each entry is 'path value'
function mage_set_store_config() {
  local entry
  local value

  for entry in "${MAGE_STORE_CONFIG[@]}"; do
    value=""
    if [[ "$entry" == *" "* ]]; then
      value="${entry#* }"
    fi

    $MAGENTO_CLI config:set "${entry%% *}" "$value" &> /dev/null
  done
}

# Disable the modules of MAGE_DISABLE_MODULES that the install has, as not
# every edition has all of them, such as MageOS_ThemeOptimization
function mage_setup_disable_modules() {
  local modules=()
  local module

  for module in "${MAGE_DISABLE_MODULES[@]}"; do
    if grep -q "'${module}'" app/etc/config.php; then
      modules+=("$module")
    fi
  done

  if [[ ${#modules[@]} -gt 0 ]]; then
    mage_info "Disabling ${modules[*]}"
    $MAGENTO_CLI module:disable "${modules[@]}"
  fi
}

function mage_add_gitignore() {
  if [[ -e .gitignore ]]; then
    mage_info "A .gitignore is already present, skipping"
    return
  fi

  local template
  template="$(mage_template_file "magento.gitignore")"

  if [[ -z "$template" ]]; then
    mage_warn "Could not get the gitignore from ${MAGE_TEMPLATES_ARCHIVE}"
    return 1
  fi

  cp "$template" .gitignore
  mage_info "Added .gitignore for Magento"
}

# Print where to find the new store, with the cd hint when the second argument is 'true'
function mage_getting_started() {
  local name="$1"
  local url="https://${name}.${MAGE_DOMAIN}/"

  mage_info ""
  mage_info "${GREEN}${name} is ready!${RESET}"

  if [[ "$2" == true ]]; then
    mage_info "Enter your project using ${BLUE}cd ./${name}${RESET}"
  fi

  mage_info "Store: ${BLUE}${url}${RESET}"
  mage_info "Admin: ${BLUE}${url}${name//-/}_admin${RESET} (${MAGE_ADMIN_USER} / ${MAGE_ADMIN_PASS})"
  mage_info ""
  mage_warn "Don't forget to configure your currency rates in the admin panel to enable multi-pricing (e.g. for Pounds)!"
}
