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
    --page-cache=redis \
    --page-cache-redis-server="${MAGE_REDIS_HOST}" \
    --page-cache-redis-db=1 \
    --admin-firstname="${MAGE_ADMIN_FIRSTNAME}" \
    --admin-lastname="${MAGE_ADMIN_LASTNAME}" \
    --admin-email="${MAGE_ADMIN_EMAIL}" \
    --admin-user="${MAGE_ADMIN_USER}" \
    --admin-password="${MAGE_ADMIN_PASS}" || return 1

  mage_info "Setting default values for Store config"
  $MAGENTO_CLI config:set general/store_information/name "$name" &> /dev/null

  local entry
  local value

  for entry in "${MAGE_STORE_CONFIG[@]}"; do
    value=""
    if [[ "$entry" == *" "* ]]; then
      value="${entry#* }"
    fi

    $MAGENTO_CLI config:set "${entry%% *}" "$value" &> /dev/null
  done

  $MAGENTO_CLI deploy:mode:set developer

  mage_info "Disabling 2FA"
  local tfa_modules="Magento_TwoFactorAuth"
  if grep -q 'Magento_AdminAdobeImsTwoFactorAuth' app/etc/config.php; then
    tfa_modules="Magento_AdminAdobeImsTwoFactorAuth ${tfa_modules}"
  fi
  $MAGENTO_CLI module:disable $tfa_modules

  env_call setup_finish "$name"

  mage_cleanup_sample_files
  mage_add_gitignore
}

function mage_cleanup_sample_files() {
  mkdir -p dev/sample-files
  find . -maxdepth 1 -type f -name "*.sample" -exec mv {} dev/sample-files/ \;
  mage_info "All files ending with '.sample' have been moved to 'dev/sample-files'"
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
