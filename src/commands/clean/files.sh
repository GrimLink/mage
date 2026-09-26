MAGE_CLEAN_HANDLERS+=("files|Remove generated code, static files and file caches")

MAGE_CLEAN_FILES=(
  generated/code
  generated/metadata
  pub/static
  var/cache
  var/composer_home
  var/page_cache
  var/view_preprocessed
)

# Empty the folders in one remove, as each call costs a container exec.
# The glob skips dotfiles, so pub/static/.htaccess stays.
function mage_clean_files() {
  local dir
  local targets=()

  for dir in "${MAGE_CLEAN_FILES[@]}"; do
    if [[ -d "$dir" ]]; then
      targets+=("$dir"/*)
    fi
  done

  local status=0

  if [[ ${#targets[@]} -gt 0 ]]; then
    $PURGE_CLI "${targets[@]}"
    status=$?
  fi

  for dir in "${MAGE_CLEAN_FILES[@]}"; do
    mage_check "$status" "$dir"
  done
}
