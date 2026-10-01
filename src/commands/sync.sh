# Pull pub/media from a server over ssh, and with --db also the latest backup of
# 'mage backup' on the server. The host is required, the Magento root on the
# server is the second argument or MAGE_SYNC_PATH.
function mage_cmd_sync() {
  local host=""
  local path=""
  local db=0
  local arg

  for arg in "$@"; do
    case "$arg" in
      --db) db=1 ;;
      -*)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
      *)
        if [[ -z "$host" ]]; then
          host="$arg"
        elif [[ -z "$path" ]]; then
          path="$arg"
        else
          mage_error "Unknown argument '${arg}'"
          exit 1
        fi
        ;;
    esac
  done

  if [[ -z "$host" ]]; then
    mage_error "Give the ssh host of the server, such as 'mage sync app@store.hypernode.io'"
    exit 1
  fi

  path="${path:-$MAGE_SYNC_PATH}"
  path="${path%/}"

  if [[ $db == 1 ]]; then
    mage_sync_backup "$host" "$path" || exit 1
  fi

  local excludes=()
  local exclude

  # Anchored to the media folder, the root of the transfer
  for exclude in "${MAGE_BACKUP_MEDIA_EXCLUDE[@]}"; do
    excludes+=("--exclude=/${exclude}")
  done

  mage_info "Syncing pub/media from ${host}..."
  mkdir -p pub

  if ! $SYNC_RSYNC_CLI -aP "${excludes[@]}" "${host}:${path}/pub/media" pub/; then
    mage_check 1 "Could not sync pub/media from ${host}:${path}"
    exit 1
  fi

  mage_check 0 "Media from ${host}:${path}"
}

# Pull the latest backup of the server into the local backup dir, for 'mage restore'
function mage_sync_backup() {
  local host="$1"
  local path="$2"
  local dir="$MAGE_BACKUP_DIR"

  if [[ "$dir" != /* ]]; then
    dir="${path}/${dir}"
  fi

  local file
  file="$($SSH_CLI "$host" "ls -t '${dir}'/*.sql.gz 2> /dev/null | head -n 1")"

  if [[ -z "$file" ]]; then
    mage_error "No backup found in ${host}:${dir}, run 'mage backup' on the server first"
    return 1
  fi

  mage_info "Pulling $(basename "$file") from ${host}..."
  mkdir -p "$MAGE_BACKUP_DIR" || return 1

  if ! $SYNC_RSYNC_CLI -aP "${host}:${file}" "${MAGE_BACKUP_DIR}/"; then
    mage_check 1 "Could not pull ${file}"
    return 1
  fi

  mage_check 0 "Backup in ${MAGE_BACKUP_DIR}/$(basename "$file"), restore it with 'mage restore'"
}
