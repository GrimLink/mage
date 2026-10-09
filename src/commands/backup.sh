# The media folders that Magento rebuilds on its own, left out of the media backup
MAGE_BACKUP_MEDIA_EXCLUDE=(
  media/catalog/product/cache
  media/captcha
  media/tmp
)

# Back up the database, and optionally pub/media, to set the project up on another device.
# The code is left to git.
function mage_cmd_backup() {
  local media=""
  local strip="$MAGE_BACKUP_STRIP"
  local arg

  for arg in "$@"; do
    case "$arg" in
      --media) media=1 ;;
      --no-media) media=0 ;;
      --strip=*) strip="${arg#--strip=}" ;;
      *)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
    esac
  done

  if [[ -z "$media" ]]; then
    media=0

    if mage_confirm "Also back up pub/media?"; then
      media=1
    fi
  fi

  mkdir -p "$MAGE_BACKUP_DIR" || exit 1

  local dir
  local name
  dir="$(cd "$MAGE_BACKUP_DIR" && pwd)"
  name="$(basename "$PWD")-$(date +%Y%m%d-%H%M%S)"

  local db_file="${dir}/${name}.sql.gz"

  mage_info "Dumping the database..."

  if ! env_call backup_db "$db_file" "$strip"; then
    rm -f "$db_file"
    mage_check 1 "Could not dump the database"
    exit 1
  fi

  mage_check 0 "Database: ${db_file}"

  if [[ $media == 1 ]]; then
    local media_file="${dir}/${name}-media.tar.gz"

    mage_info "Archiving pub/media..."

    if ! mage_backup_media "$media_file"; then
      rm -f "$media_file"
      mage_check 1 "Could not archive pub/media"
      exit 1
    fi

    mage_check 0 "Media: ${media_file}"
  fi

  # SSH_CONNECTION holds the client ip and port, then the server ip and port
  # rsync -P resumes an interrupted copy, and the quotes leave the glob to the server
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    local server
    local port
    local ssh=""
    read -r _ _ server port <<< "$SSH_CONNECTION"

    if [[ "$port" != 22 ]]; then
      ssh="-e 'ssh -p ${port}' "
    fi

    mage_notice "Copy it to your device with: rsync -P ${ssh}'${USER}@${server}:${dir}/${name}*' ."
  fi
}

# Archive pub/media, without the folders Magento rebuilds
function mage_backup_media() {
  if [[ ! -d pub/media ]]; then
    mage_error "pub/media not found"
    return 1
  fi

  local excludes=()
  local path

  for path in "${MAGE_BACKUP_MEDIA_EXCLUDE[@]}"; do
    excludes+=("--exclude=${path}")
  done

  tar -czf "$1" "${excludes[@]}" -C pub media
}

# Without magerun, dump with mysqldump and the credentials of app/etc/env.php.
# The definers are removed, as their user does not exist on another device.
function mage_backup_mysqldump() {
  local file="$1"

  if ! command -v "${MYSQLDUMP_CLI%% *}" &> /dev/null; then
    mage_error "Neither magerun2 nor mysqldump found, install one of them"
    return 1
  fi

  mage_env_php_db
  mage_db_args

  mage_notice "magerun2 not found, dumping the whole database with mysqldump"

  MYSQL_PWD="$MAGE_DB_PASS" $MYSQLDUMP_CLI "${MAGE_DB_ARGS[@]}" --single-transaction --quick --no-tablespaces "$MAGE_DB_NAME" |
    sed -e 's/DEFINER=[^*]*\*/\*/' |
    gzip > "$file"
}
