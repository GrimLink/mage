load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  make_magento_root "$BATS_TEST_TMPDIR"
  MAGE_ROOT="$BATS_TEST_TMPDIR"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"
  LINT_PHP_CLI="echo php"
  LINT_COMPOSER_CLI="fake_lint_composer"
  mkdir -p "$(mage_lint_dir)/vendor/bin"
  touch "$(mage_lint_dir)/vendor/bin/phpcs" "$(mage_lint_dir)/vendor/bin/phpcbf"
}

# Echo the composer command, and create the install it would make
function fake_lint_composer() {
  echo "composer $*"
  mkdir -p "${@: -1}/vendor/bin"
  touch "${@: -1}/vendor/bin/phpcs"
}

@test "lints a path from the current folder, with the phpcs options" {
  mkdir -p app/code/Acme
  MAGE_CALL_DIR="${BATS_TEST_TMPDIR}/app/code"

  run mage_cmd_lint Acme -s --report=summary
  [ "$output" = "php $(mage_lint_dir)/vendor/bin/phpcs --standard=HyvaThemes -p -s --report=summary app/code/Acme" ]
}

@test "lints a package in vendor" {
  run mage_cmd_lint vendor/hyva-themes/magento2-theme-module
  [ "$status" -eq 0 ]
  [ "$output" = "php $(mage_lint_dir)/vendor/bin/phpcs --standard=HyvaThemes -p vendor/hyva-themes/magento2-theme-module" ]
}

@test "fixes with phpcbf" {
  run mage_cmd_lint app/code --fix
  [ "$output" = "php $(mage_lint_dir)/vendor/bin/phpcbf --standard=HyvaThemes -p app/code" ]
}

@test "never lints the whole project" {
  run mage_cmd_lint -s
  [ "$status" -eq 1 ]
  [[ "$output" == *"Give a path to lint"* ]]
  [[ "$output" != *"phpcs"* ]]
}

@test "installs the coding standard on the first run" {
  rm -rf "$(mage_lint_dir)"

  run mage_cmd_lint app/code
  [ "$status" -eq 0 ]
  [[ "$output" == *"composer create-project --no-plugins --no-dev --no-interaction hyva-themes/hyva-coding-standard $(mage_lint_dir).tmp"* ]]
  [[ "$output" == *"php $(mage_lint_dir)/vendor/bin/phpcs --standard=HyvaThemes -p app/code" ]]
  [ ! -e "$(mage_lint_dir).tmp" ]
}

@test "keeps the current coding standard when an install fails" {
  function fake_lint_composer() { return 1; }

  run mage_lint_install
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not install"* ]]
  [ -f "$(mage_lint_dir)/vendor/bin/phpcs" ]
  [ ! -e "$(mage_lint_dir).tmp" ]
}

@test "reinstalls the coding standard with --update, also without a path" {
  run mage_cmd_lint --update
  [ "$status" -eq 0 ]
  [[ "$output" == *"composer create-project"* ]]
  [[ "$output" != *"phpcs --standard"* ]]
}

@test "installs and runs in the project with a container" {
  LINT_IN_PROJECT=1
  PURGE_CLI="echo purge"
  function fake_container_php() {
    if [[ "$1" == "-r" ]]; then
      echo "php $*"
      [[ "$2" != *"is_file"* ]]
      return
    fi
    echo "php $*"
  }
  LINT_PHP_CLI="fake_container_php"

  run mage_cmd_lint app/code
  [ "$status" -eq 0 ]
  [[ "$output" == *"composer create-project --no-plugins --no-dev --no-interaction hyva-themes/hyva-coding-standard hyva-coding-standard.tmp"* ]]
  [[ "$output" == *"purge hyva-coding-standard"* ]]
  [[ "$output" == *"rename('hyva-coding-standard.tmp', 'hyva-coding-standard')"* ]]
  [[ "${lines[${#lines[@]}-1]}" == "php hyva-coding-standard/vendor/bin/phpcs --standard=HyvaThemes -p app/code" ]]
}

@test "lints an absolute path in the project relative to it with a container" {
  LINT_IN_PROJECT=1
  LINT_PHP_CLI="echo php"

  run mage_cmd_lint "${BATS_TEST_TMPDIR}/app/code"
  [ "$status" -eq 0 ]
  [ "${lines[${#lines[@]}-1]}" = "php hyva-coding-standard/vendor/bin/phpcs --standard=HyvaThemes -p app/code" ]
}

@test "refuses a path outside the project with a container" {
  LINT_IN_PROJECT=1
  LINT_PHP_CLI="echo php"

  run mage_cmd_lint /tmp/elsewhere
  [ "$status" -eq 1 ]
  [[ "$output" == *"The container only sees the project"* ]]
}
