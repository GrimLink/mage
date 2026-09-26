# mage add <file>.json applies a composer fragment: a json file with the
# composer.json keys below. {{NAME}} placeholders are asked when applied.
MAGE_ADD_JSON_KEYS="description repositories config auth require require-dev"

# Apply a composer fragment, in the order auth, repositories, config and packages,
# so the packages can use the repositories and credentials they need
function mage_add_json() {
  if ! command -v jq &> /dev/null; then
    mage_error "Adding from a json file requires jq, install it with 'brew install jq' or your package manager"
    exit 1
  fi

  local file
  file="$(mage_resolve_path "$1")"

  if [[ ! -f "$file" ]]; then
    mage_error "File not found: $1"
    exit 1
  fi

  if ! jq -e 'type == "object"' "$file" &> /dev/null; then
    mage_error "$1 is not a json object"
    exit 1
  fi

  mage_add_json_check_keys "$file"

  local json
  json="$(mage_add_json_fill "$file")" || exit 1

  local description
  description="$(jq -r '.description // empty' <<< "$json")"
  if [[ -n "$description" ]]; then
    mage_info "Adding ${description}"
  fi

  mage_add_json_auth "$json" &&
    mage_add_json_repositories "$json" &&
    mage_add_json_config "$json" &&
    mage_add_json_require "$json" require &&
    mage_add_json_require "$json" require-dev --dev
}

# Warn about keys that are not applied, such as a typo
function mage_add_json_check_keys() {
  local key

  for key in $(jq -r 'keys_unsorted[]' "$1"); do
    if [[ " $MAGE_ADD_JSON_KEYS " != *" $key "* ]]; then
      mage_warn "Skipping the unknown key '${key}', use one of: ${MAGE_ADD_JSON_KEYS}"
    fi
  done
}

# Echo the json with each {{NAME}} replaced by its answer, where MAGE_VAR_<NAME>
# from the config is the default. Placeholders in auth are secrets, so their input is hidden.
function mage_add_json_fill() {
  local file="$1"
  local content
  content="$(cat "$file")"

  local secrets
  secrets=" $(jq -r '.auth // {} | .. | strings' "$file" | grep -o '{{[A-Z0-9_]*}}' | tr -d '{}' | tr '\n' ' ') "

  local name
  local default_var
  local value

  for name in $(grep -o '{{[A-Z0-9_]*}}' "$file" | tr -d '{}' | sort -u); do
    default_var="MAGE_VAR_${name}"
    value=""

    if [[ "$secrets" == *" $name "* ]]; then
      if [[ -n "${!default_var}" ]]; then
        read -r -s -p "${name} (set in config): " value
      else
        read -r -s -p "${name}: " value
      fi
      echo "" >&2
      value="${value:-${!default_var}}"
    else
      value="$(mage_ask "$name" "${!default_var}")"
    fi

    if [[ -z "$value" ]]; then
      mage_error "No value given for {{${name}}}"
      return 1
    fi

    # The value lands inside a json string
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    content="${content//\{\{${name}\}\}/${value}}"
  done

  printf '%s\n' "$content"
}

# Store the credentials in the global composer auth, so they never end up in the project.
# http-basic takes a username and password, the other types such as gitlab-token a single token.
function mage_add_json_auth() {
  local type
  local host
  local user
  local pass

  while IFS=$'\t' read -r type host user pass; do
    if [[ "$type" == "http-basic" ]]; then
      $COMPOSER_CLI config --global --auth "${type}.${host}" "$user" "$pass" || return 1
    else
      $COMPOSER_CLI config --global --auth "${type}.${host}" "$user" || return 1
    fi

    mage_check 0 "Auth ${type} for ${host}"
  done < <(jq -r '.auth // {} | to_entries[] | .key as $type | .value | to_entries[] | [$type, .key] + (if (.value | type) == "object" then [.value.username, .value.password] else [.value] end) | @tsv' <<< "$1")
}

# Repositories are keyed by name, as composer config needs a name for each
function mage_add_json_repositories() {
  local json="$1"
  local name

  if [[ "$(jq -r '.repositories // {} | type' <<< "$json")" != "object" ]]; then
    mage_error "The repositories should be an object keyed by name"
    return 1
  fi

  for name in $(jq -r '.repositories // {} | keys_unsorted[]' <<< "$json"); do
    $COMPOSER_CLI config "repositories.${name}" "$(jq -c --arg name "$name" '.repositories[$name]' <<< "$json")" || return 1
    mage_check 0 "Repository ${name}"
  done
}

# Nested keys become dotted composer config keys, such as allow-plugins.vendor/name
function mage_add_json_config() {
  local json="$1"
  local key
  local value

  for key in $(jq -r '.config // {} | paths(type == "array") | join(".")' <<< "$json"); do
    mage_warn "Skipping config '${key}', lists are not supported"
  done

  while IFS=$'\t' read -r key value; do
    $COMPOSER_CLI config "$key" "$value" || return 1
    mage_check 0 "Config ${key}"
  done < <(jq -r '.config // {} | paths(type != "object") as $p | if ($p | all(type == "string")) and (getpath($p) | type != "array") then [($p | join(".")), (getpath($p) | tostring)] | @tsv else empty end' <<< "$json")
}

# Require the packages of the given key in one composer run, with any extra arguments
function mage_add_json_require() {
  local json="$1"
  local key="$2"
  shift 2

  local packages=()
  local package

  while IFS= read -r package; do
    packages+=("$package")
  done < <(jq -r --arg key "$key" '.[$key] // {} | to_entries[] | "\(.key):\(.value)"' <<< "$json")

  if [[ ${#packages[@]} -gt 0 ]]; then
    $COMPOSER_CLI require "$@" "${packages[@]}"
  fi
}
