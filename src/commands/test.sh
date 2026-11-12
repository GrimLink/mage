# The project file of mage, its test list holds the actions mage test runs
MAGE_PROJECT_FILE="mage.config.json"

# Run each action of the test list in mage.config.json as a shell command from the root,
# where 'mage' is this mage, such as 'mage lint'. All run, and it fails when any fails.
function mage_cmd_test() {
  local arg

  for arg in "$@"; do
    case "$arg" in
      -y | --yes) MAGE_YES=1 ;;
      *)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
    esac
  done

  mage_require_jq "Testing"

  if [[ ! -f "$MAGE_PROJECT_FILE" ]]; then
    mage_test_init || exit 1
  fi

  if ! jq -e '.test | type == "array" and length > 0 and all(type == "string")' "$MAGE_PROJECT_FILE" &> /dev/null; then
    mage_error "The test of ${MAGE_PROJECT_FILE} should be a list of shell commands, such as [\"mage lint\"]"
    exit 1
  fi

  local blocked
  blocked="$(jq -r --arg re "$(mage_test_blocked_pattern)" '.test[] | select(test($re))' "$MAGE_PROJECT_FILE")"

  if [[ -n "$blocked" ]]; then
    mage_error "mage test never runs actions that remove, move or write files, such as rm, mv or a > redirect:"
    while IFS= read -r action; do
      mage_check 1 "$action" >&2
    done <<< "$blocked"
    exit 1
  fi

  # Read first, so an action that reads stdin cannot take the remaining actions
  local actions=()
  local action

  while IFS= read -r action; do
    actions+=("$action")
  done < <(jq -r '.test[]' "$MAGE_PROJECT_FILE")

  export MAGE_SELF
  local failed=()

  for action in "${actions[@]}"; do
    mage_info ""
    mage_info "${BOLD}${action}${RESET}"

    if ! bash -c "function mage() { \"\$MAGE_SELF\" \"\$@\"; }; ${action}"; then
      failed+=("$action")
    fi
  done

  mage_info ""

  if [[ ${#failed[@]} -gt 0 ]]; then
    for action in "${failed[@]}"; do
      mage_check 1 "$action"
    done
    exit 1
  fi

  mage_check 0 "All tests passed"
}

# Echo the regex of the actions mage test blocks, as they change files: commands
# such as rm and mv, also after xargs or -exec, find -delete, in place edits, the git
# commands that change the working tree, mage nuke, and a redirect to anything but
# /dev/null. It guards against mistakes, it is no sandbox, a shell can always get around it.
function mage_test_blocked_pattern() {
  local start="(?:^|[\\s;&|(\`'\"])"
  local end="(?=[\\s;&|)\`'\"]|$)"
  local commands="rm|rmdir|mv|cp|dd|truncate|shred|unlink|ln|chmod|chown|chgrp|tee|rsync|mkdir|touch"
  local redirect=">>?+\\s*+(?!/dev/null${end}|&)"

  printf '%s' "${start}(?:/\\S*/|\\./)?(?:${commands})${end}"
  printf '%s' "|${start}-delete${end}"
  printf '%s' "|${start}(?:sed|perl)\\s(?:[^;&|]*\\s)?-i"
  printf '%s' "|${start}git\\s+(?:clean|reset|checkout|restore|rm|mv|stash|switch)${end}"
  printf '%s' "|${start}mage\\s+(?:nuke|destroy)${end}"
  printf '%s' "|(?<![-=0-9&])${redirect}|(?<![-=&])[0-9]${redirect}"
}

# Offer to create the mage.config.json of the project with the default test actions
function mage_test_init() {
  mage_notice "The project has no ${MAGE_PROJECT_FILE}, which lists the actions mage test runs"

  if ! mage_confirm "Create it with the default actions?" y; then
    mage_error "mage test needs a ${MAGE_PROJECT_FILE}"
    return 1
  fi

  local template
  template="$(mage_template_file "mage.config.json")"

  if [[ -z "$template" ]]; then
    mage_error "Could not get the 'mage.config.json' template from ${MAGE_TEMPLATES_ARCHIVE}"
    return 1
  fi

  cp "$template" "$MAGE_PROJECT_FILE"
  mage_check 0 "Created ${MAGE_PROJECT_FILE}"
}
