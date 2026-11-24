MAGE_EDITIONS="mage-os mage-os-minimal mage-os-mirror community enterprise"

# Create a new Magento project, install it and set it up.
# Anything not given as an option is asked, or defaulted with -y.
function mage_cmd_create() {
  local name=""
  local edition=""
  local version=""
  local env=""
  local template="$MAGE_CREATE_TEMPLATE"
  local arg

  for arg in "$@"; do
    case "$arg" in
      --edition=*) edition="${arg#*=}" ;;
      --version=*) version="${arg#*=}" ;;
      --env=*) env="${arg#*=}" ;;
      --template=*) template="${arg#*=}" ;;
      -y | --yes) MAGE_YES=1 ;;
      -*)
        mage_error "Unknown option '${arg}'"
        exit 1
        ;;
      *) name="$arg" ;;
    esac
  done

  if [[ -z "$name" ]]; then
    mage_error "No name was given for the Magento project, aborting.."
    exit 1
  fi

  if [[ "$name" == */* ]]; then
    mage_error "The name '${name}' should be a folder name, not a path"
    exit 1
  fi

  if [[ -e "$name" ]]; then
    mage_error "'${name}' already exists, aborting.."
    exit 1
  fi

  mage_require_jq "Creating a project"

  local available_envs
  available_envs="$(mage_env_available)"
  local default_env="${available_envs%% *}"

  if [[ -z "$edition" ]]; then
    edition="$(mage_choose "Edition" "$MAGE_EDITION" $MAGE_EDITIONS)" || exit 1
  fi

  if [[ -z "$version" ]]; then
    version="$(mage_ask "Magento version" "latest")" || exit 1
  fi

  if [[ -z "$env" ]]; then
    env="$(mage_choose "Environment" "$default_env" $available_envs)" || exit 1
  fi

  if [[ " $available_envs " != *" $env "* ]]; then
    mage_error "The environment '${env}' is not available, use one of: ${available_envs}"
    exit 1
  fi

  local package=""
  local repository=""

  # See the versions at:
  # - https://github.com/mage-os/mageos-magento2
  # - https://mirror.mage-os.org/
  # - https://experienceleague.adobe.com/docs/commerce-operations/release/versions.html
  case "$edition" in
    "community")
      package="magento/project-community-edition"
      repository="https://repo.magento.com/"
      ;;
    "enterprise")
      package="magento/project-enterprise-edition"
      repository="https://repo.magento.com/"
      ;;
    "mage-os")
      package="mage-os/project-community-edition"
      repository="https://repo.mage-os.org/"
      ;;
    "mage-os-minimal")
      package="mage-os/project-minimal-edition"
      repository="https://repo.mage-os.org/"
      ;;
    "mage-os-mirror")
      package="magento/project-community-edition"
      repository="https://mirror.mage-os.org/"
      ;;
    *)
      mage_error "Unknown edition '${edition}', use one of: ${MAGE_EDITIONS}"
      exit 1
      ;;
  esac

  if [[ "$version" != "latest" ]]; then
    package="${package}=${version}"
  fi

  local fragment
  fragment="$(mage_create_template_file "${template:-$(mage_create_default_template "$edition")}")" || exit 1

  mage_env_use "$env"
  mage_info "Creating '${name}' from ${package} using ${env}"

  if ! env_call create_project "$name" "$package" "$repository"; then
    mage_error "Could not create the composer project"
    exit 1
  fi

  mage_create_composer_setup "$fragment" || exit 1
  MAGE_ROOT="$PWD"
  mage_setup "$name" || exit 1
  mage_create_urn_catalog
  mage_getting_started "$name" true
}

# Generate the XML catalog for the XML language server of VS Code and Zed.
# Magento writes each schema as '../<path>', so it has to be one folder below the root.
function mage_create_urn_catalog() {
  mkdir -p .vscode

  mage_info "Generating the XML catalog in .vscode/catalog.xml"
  if ! $MAGENTO_CLI dev:urn-catalog:generate --ide=vscode .vscode/catalog.xml; then
    mage_warn "Could not generate the XML catalog"
  fi
}

# Echo the template 'mage create' applies to an edition without --template
function mage_create_default_template() {
  case "$1" in
    mage-os | mage-os-minimal) echo "$1" ;;
    *) echo "default" ;;
  esac
}

# Echo the composer fragment of a template: a json file, or the name of a bundled
# composer-create-<name>.json. Resolved before the project exists, as creating it changes folder.
function mage_create_template_file() {
  local template="$1"

  if [[ "$template" == *.json ]]; then
    if [[ "$template" != /* ]]; then
      template="${PWD}/${template}"
    fi

    if [[ ! -f "$template" ]]; then
      mage_error "Template file not found: ${1}"
      return 1
    fi

    echo "$template"
    return
  fi

  if ! mage_template_file "composer-create-${template}.json"; then
    mage_error "Unknown template '${template}', use one of: $(mage_create_templates) or a path to a json file"
    return 1
  fi
}

# Echo the names of the bundled templates
function mage_create_templates() {
  local dir
  local file
  local names=""

  dir="$(mage_templates_dir)" || return 0

  for file in "$dir"/composer-create-*.json; do
    [[ -f "$file" ]] || continue
    file="${file##*/composer-create-}"
    names="${names:+$names, }${file%.json}"
  done

  echo "$names"
}

# Configure composer for local development, apply the template and install the project
function mage_create_composer_setup() {
  local fragment="$1"

  mage_info "Adjusting composer settings to allow dev packages"
  $COMPOSER_CLI config minimum-stability dev
  $COMPOSER_CLI config prefer-stable true

  mage_add_path_repository

  mage_add_json "$fragment" --no-update || return 1
  mage_create_legacy_packages

  mage_info "Running installation.. Enjoy a cup of coffee in the meantime"
  $COMPOSER_CLI install
}

# MAGE_PACKAGES and MAGE_DEV_PACKAGES are deprecated for templates, and will be dropped
function mage_create_legacy_packages() {
  if [[ ${#MAGE_PACKAGES[@]} -eq 0 ]] && [[ ${#MAGE_DEV_PACKAGES[@]} -eq 0 ]]; then
    return 0
  fi

  mage_warn "MAGE_PACKAGES and MAGE_DEV_PACKAGES are deprecated, move them to a template, see 'mage create' in the docs"

  if [[ ${#MAGE_PACKAGES[@]} -gt 0 ]]; then
    $COMPOSER_CLI require --no-update "${MAGE_PACKAGES[@]}"
  fi

  if [[ ${#MAGE_DEV_PACKAGES[@]} -gt 0 ]]; then
    $COMPOSER_CLI require --no-update --dev "${MAGE_DEV_PACKAGES[@]}"
  fi
}
