load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  echo '{}' > composer.json
}

# Create a bare repository holding a composer package, echo its url
function make_git_package() {
  local tag="$1"
  local work="${BATS_TEST_TMPDIR}/work"

  git init --quiet -b main "$work"
  echo '{ "name": "vendor/example" }' > "${work}/composer.json"
  git -C "$work" add composer.json
  git -C "$work" -c user.name=test -c user.email=test@example.com commit --quiet -m init

  if [[ -n "$tag" ]]; then
    git -C "$work" tag "$tag"
  fi

  git clone --quiet --bare "$work" "${BATS_TEST_TMPDIR}/example.git"
  echo "${BATS_TEST_TMPDIR}/example.git"
}

@test "errors without arguments" {
  run mage_cmd_add
  [ "$status" -eq 1 ]
  [[ "$output" == *"add [GIT_URL]"* ]]
}

@test "passes anything else as is to composer require" {
  run mage_cmd_add vendor/pkg:^2.0 other/pkg --dev
  [ "$output" = "composer require vendor/pkg:^2.0 other/pkg --dev" ]
}

@test "runs a registered handler with the remaining arguments" {
  MAGE_ADD_HANDLERS+=("hyva-checkout|Add the Hyva Checkout")
  function mage_add_hyva_checkout() {
    echo "handler $*"
  }

  run mage_cmd_add hyva-checkout one two
  [ "$output" = "handler one two" ]
}

@test "lists the handlers in the help" {
  MAGE_ADD_HANDLERS+=("theme|Create a new theme")

  run mage_cmd_add help
  [ "$status" -eq 0 ]
  [[ "$output" == *"add theme"*"Create a new theme"* ]]
}

@test "ignores functions that are not registered as a handler" {
  run mage_cmd_add git
  [ "$output" = "composer require git" ]
}

@test "requires a tagged clone as its branch aliased to the tag" {
  local url
  url="$(make_git_package v1.2.0)"

  run mage_cmd_add "$url" --dev
  [ "$status" -eq 0 ]
  [ -f package-source/vendor/example/composer.json ]
  [[ "$output" == *"composer config repositories.local-packages path package-source/*/*"* ]]
  [[ "$output" == *"composer require vendor/example:dev-main as 1.2.0 --dev"* ]]
}

@test "requires a clone without tags as @dev" {
  local url
  url="$(make_git_package)"

  run mage_cmd_add "$url"
  [[ "$output" == *"composer require vendor/example:@dev"* ]]
}

@test "reuses an existing clone" {
  local url
  url="$(make_git_package)"
  mage_cmd_add "$url" > /dev/null 2>&1

  run mage_cmd_add "$url"
  [[ "$output" == *"Using the existing clone in package-source/vendor/example"* ]]
  [[ "$output" != *"Cloning"* ]]
}

@test "skips the path repository when it is registered" {
  local url
  url="$(make_git_package)"
  echo '{ "repositories": { "local-packages": {} } }' > composer.json

  run mage_cmd_add "$url"
  [[ "$output" != *"composer config"* ]]
}
