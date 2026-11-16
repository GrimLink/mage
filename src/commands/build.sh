# Build with the npm scripts of the package.json files in app/design and package-source.
# Without a target the build.themes of mage.config.json are built, or else every theme.
# A target matches part of the path, so it can also pick a module.
# --watch runs the watch script of one target instead.
function mage_cmd_build() {
  local watch=0
  local target=""
  local arg

  for arg in "$@"; do
    case "$arg" in
      -w | --watch) watch=1 ;;
      -*)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
      *) target="$arg" ;;
    esac
  done

  if [[ "$target" == "hyva" ]]; then
    mage_build_hyva "$watch"
    return
  fi

  local script="$MAGE_BUILD_SCRIPT"
  if [[ $watch == 1 ]]; then
    script="$MAGE_WATCH_SCRIPT"
  fi

  mage_require_jq "Building"

  local terms=()
  local term

  if [[ -n "$target" ]]; then
    terms=("$target")
  else
    local themes
    themes="$(mage_build_config_themes)" || exit 1

    if [[ -n "$themes" ]]; then
      while IFS= read -r term; do
        terms+=("$term")
      done <<< "$themes"
    fi
  fi

  if [[ $watch == 1 ]] && [[ ${#terms[@]} -eq 0 ]]; then
    mage_error "Watching needs a target, such as 'mage build my-theme --watch'"
    exit 1
  fi

  local dirs=()
  local dir
  local found

  if [[ ${#terms[@]} -eq 0 ]]; then
    while IFS= read -r dir; do
      dirs+=("$dir")
    done < <(mage_build_targets "$script" "")

    if [[ ${#dirs[@]} -eq 0 ]]; then
      mage_error "No theme in app/design or package-source has a package.json with a '${script}' script"
      exit 1
    fi
  fi

  for term in "${terms[@]}"; do
    found=0

    while IFS= read -r dir; do
      found=1
      if [[ " ${dirs[*]} " != *" ${dir} "* ]]; then
        dirs+=("$dir")
      fi
    done < <(mage_build_targets "$script" "$term")

    if [[ $found == 0 ]]; then
      if [[ -n "$target" ]]; then
        mage_error "No package.json with a '${script}' script matches '${term}'"
      else
        mage_error "No package.json with a '${script}' script matches '${term}' of the build.themes in ${MAGE_PROJECT_FILE}"
      fi
      exit 1
    fi
  done

  if [[ $watch == 1 ]]; then
    dir="$(mage_build_pick "${dirs[@]}")" || exit 1
    mage_npm_run "$dir" "$script"
    return
  fi

  local status=0

  for dir in "${dirs[@]}"; do
    mage_npm_run "$dir" "$script" || status=1
  done

  return $status
}

# Echo the build.themes of mage.config.json, one per line, nothing without them
function mage_build_config_themes() {
  if [[ ! -f "$MAGE_PROJECT_FILE" ]] || ! jq -e 'has("build")' "$MAGE_PROJECT_FILE" &> /dev/null; then
    return 0
  fi

  if ! jq -e '.build | type == "object" and (.themes | type == "array" and all(type == "string" and length > 0))' "$MAGE_PROJECT_FILE" &> /dev/null; then
    mage_error "The build of ${MAGE_PROJECT_FILE} should hold a list of themes, such as { \"themes\": [\"my-theme\"] }"
    return 1
  fi

  jq -r '.build.themes[]' "$MAGE_PROJECT_FILE"
}

# Echo the folders with a package.json that has the script. Without a term only
# themes count, their package root holds a theme.xml. A term matches part of the path.
function mage_build_targets() {
  local script="$1"
  local term="$2"
  local file
  local dir

  while IFS= read -r file; do
    dir="$(dirname "$file")"

    if ! jq -e --arg script "$script" '.scripts[$script]' "$file" &> /dev/null; then
      continue
    fi

    if [[ -n "$term" ]]; then
      if [[ "$(mage_lower_case "$dir")" == *"$(mage_lower_case "$term")"* ]]; then
        echo "$dir"
      fi
    elif [[ -f "$(mage_build_package_root "$dir")/theme.xml" ]]; then
      echo "$dir"
    fi
  done < <(find app/design package-source -name package.json -not -path "*/node_modules/*" 2> /dev/null | sort)
}

# Echo the root of the package a folder is in, such as app/design/frontend/Vendor/theme
# or package-source/vendor/package
function mage_build_package_root() {
  local dir="$1"

  case "$dir" in
    app/design/*) echo "$dir" | cut -d / -f 1-5 ;;
    package-source/*) echo "$dir" | cut -d / -f 1-3 ;;
  esac
}

# Echo the one folder to watch, asking which when there are more
function mage_build_pick() {
  if [[ $# -eq 1 ]]; then
    echo "$1"
    return
  fi

  local i=1
  local dir

  for dir in "$@"; do
    mage_info "  ${i}) ${dir}" >&2
    i=$((i + 1))
  done

  local choice
  choice="$(mage_ask "Which one to watch [1-$#]")" || return 1

  if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt $# ]]; then
    mage_error "Pick a number from 1 to $#"
    return 1
  fi

  echo "${!choice}"
}

# Run an npm script in a folder, installing its packages first when they are missing
function mage_npm_run() {
  local dir="$1"
  local script="$2"

  if [[ ! -d "${dir}/node_modules" ]]; then
    if [[ -f "${dir}/package-lock.json" ]]; then
      $NPM_CLI --prefix "$dir" ci || return 1
    else
      $NPM_CLI --prefix "$dir" install || return 1
    fi
  fi

  mage_info "Running '${script}' in ${dir}"
  $NPM_CLI --prefix "$dir" run "$script"
}

# The Hyva default theme in vendor, the CSP variant when that is installed
function mage_build_hyva() {
  local dir="vendor/hyva-themes/magento2-default-theme/web/tailwind"

  if [[ -d vendor/hyva-themes/magento2-default-theme-csp/web/tailwind ]]; then
    dir="vendor/hyva-themes/magento2-default-theme-csp/web/tailwind"
  fi

  if [[ ! -d "$dir" ]]; then
    mage_error "The Hyva default theme is not installed"
    exit 1
  fi

  if [[ "$1" == 1 ]]; then
    mage_npm_run "$dir" "$MAGE_WATCH_SCRIPT"
  else
    mage_npm_run "$dir" "$MAGE_BUILD_SCRIPT"
  fi
}
