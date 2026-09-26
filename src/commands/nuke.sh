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

  env_call nuke "$name"

  if [[ $keep_files == 0 ]]; then
    cd .. || exit 1
    rm -rf "$root"
    mage_check 0 "Removed ${root}"
    mage_notice "Your shell is still in the removed folder, run 'cd ..'"
  fi

  mage_info "Nuke complete."
}
