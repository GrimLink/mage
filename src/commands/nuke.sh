# Permanently delete the project: search indices, database, environment and files
function mage_cmd_nuke() {
  local keep_files=0
  local arg

  for arg in "$@"; do
    case "$arg" in
      --keep-files) keep_files=1 ;;
      *)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
    esac
  done

  local root="$PWD"
  local name
  name="$(basename "$root")"

  if [[ "$root" == "/" ]] || [[ "$root" == "$HOME" ]]; then
    mage_error "Refusing to nuke ${root}"
    exit 1
  fi

  if [[ $keep_files == 1 ]]; then
    mage_warn "This permanently deletes the database and environment of ${root}"
  else
    mage_warn "This permanently deletes the Magento project in ${root}, including all files"
  fi

  local answer=""
  read -r -p "Type '${name}' to confirm: " answer

  if [[ "$answer" != "$name" ]]; then
    mage_info "Aborting nuke.."
    exit 1
  fi

  local db_name
  db_name="$(mage_env_php db/connection/default/dbname)"
  db_name="${db_name:-$name}"
  MAGE_DB_HOST="$(mage_env_php db/connection/default/host || echo "$MAGE_DB_HOST")"
  MAGE_DB_USER="$(mage_env_php db/connection/default/username || echo "$MAGE_DB_USER")"
  MAGE_DB_PASS="$(mage_env_php db/connection/default/password || echo "$MAGE_DB_PASS")"

  env_call nuke "$name" "$db_name"

  if [[ $keep_files == 0 ]]; then
    cd .. || exit 1
    rm -rf "$root"
    mage_check 0 "Removed ${root}"
    mage_notice "Your shell is still in the removed folder, run 'cd ..'"
  fi

  mage_info "Nuke complete."
}

# Delete the search indices of the project, using the OpenSearch config
# from Magento, so this has to run before the database is dropped
function mage_clear_opensearch() {
  local host="$MAGE_SEARCH_HOST"
  local port="$MAGE_SEARCH_PORT"
  local prefix="$1"
  local line

  while IFS= read -r line; do
    case "$line" in
      "catalog/search/opensearch_server_hostname - "*) host="${line#* - }" ;;
      "catalog/search/opensearch_server_port - "*) port="${line#* - }" ;;
      "catalog/search/opensearch_index_prefix - "*) prefix="${line#* - }" ;;
    esac
  done < <($MAGENTO_CLI config:show catalog/search 2> /dev/null)

  if [[ -z "$prefix" ]]; then
    mage_check 1 "Could not determine the OpenSearch index prefix"
    return 1
  fi

  if curl -fs -X DELETE "${host}:${port}/${prefix}_*" > /dev/null; then
    mage_check 0 "OpenSearch indices with prefix '${prefix}_' cleared"
  else
    mage_check 1 "Could not clear the OpenSearch indices with prefix '${prefix}_'"
  fi
}
