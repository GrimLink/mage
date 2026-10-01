MAGE_EDITIONS="mage-os community enterprise"

# Create a new Magento project, install it and set it up.
# Anything not given as an option is asked, or defaulted with -y.
function mage_cmd_create() {
  local name=""
  local edition=""
  local version=""
  local env=""
  local assume_yes=0
  local arg

  for arg in "$@"; do
    case "$arg" in
      --edition=*) edition="${arg#*=}" ;;
      --version=*) version="${arg#*=}" ;;
      --env=*) env="${arg#*=}" ;;
      -y | --yes) assume_yes=1 ;;
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

  local available_envs
  available_envs="$(mage_env_available)"
  local default_env="${available_envs%% *}"

  if [[ $assume_yes == 1 ]]; then
    edition="${edition:-$MAGE_EDITION}"
    version="${version:-latest}"
    env="${env:-$default_env}"
  fi

  if [[ -z "$edition" ]]; then
    edition="$(mage_ask "Edition [${MAGE_EDITIONS}]" "$MAGE_EDITION")"
  fi

  if [[ -z "$version" ]]; then
    version="$(mage_ask "Magento version" "latest")"
  fi

  if [[ -z "$env" ]]; then
    env="$(mage_ask "Environment [${available_envs}]" "$default_env")"
  fi

  if [[ " $available_envs " != *" $env "* ]]; then
    mage_error "The environment '${env}' is not available, use one of: ${available_envs}"
    exit 1
  fi

  local package=""
  local repository=""

  # See the versions at:
  # - https://github.com/mage-os/mageos-magento2
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
    *)
      mage_error "Unknown edition '${edition}', use one of: ${MAGE_EDITIONS}"
      exit 1
      ;;
  esac

  if [[ "$version" != "latest" ]]; then
    package="${package}=${version}"
  fi

  mage_env_use "$env"
  mage_info "Creating '${name}' from ${package} using ${env}"

  if ! env_call create_project "$name" "$package" "$repository"; then
    mage_error "Could not create the composer project"
    exit 1
  fi

  mage_create_composer_setup || exit 1
  MAGE_ROOT="$PWD"
  mage_setup "$name" || exit 1
  mage_getting_started "$name" true
}

# Configure composer for local development and install the project
function mage_create_composer_setup() {
  mage_info "Adjusting composer settings to allow dev packages"
  $COMPOSER_CLI config minimum-stability dev
  $COMPOSER_CLI config prefer-stable true
  $COMPOSER_CLI config allow-plugins.cweagans/composer-patches true

  mage_add_path_repository

  if [[ ${#MAGE_PACKAGES[@]} -gt 0 ]]; then
    mage_info "Adding default packages"
    $COMPOSER_CLI require --no-update "${MAGE_PACKAGES[@]}"
  fi

  if [[ ${#MAGE_DEV_PACKAGES[@]} -gt 0 ]]; then
    $COMPOSER_CLI require --no-update --dev "${MAGE_DEV_PACKAGES[@]}"
  fi

  mage_info "Running installation.. Enjoy a cup of coffee in the meantime"
  $COMPOSER_CLI install
}
