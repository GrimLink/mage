load helper

# Write a package.json with the given npm scripts
function make_package() {
  local dir="$1"
  shift
  local scripts=""
  local script

  for script in "$@"; do
    scripts="${scripts:+$scripts, }\"${script}\": \"x\""
  done

  mkdir -p "${dir}/node_modules"
  echo "{ \"scripts\": { ${scripts} } }" > "${dir}/package.json"
}

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  NPM_CLI="echo npm"

  mkdir -p app/design/frontend/Vendor/shop package-source/vendor/magento2-theme-b2b package-source/vendor/magento2-module
  touch app/design/frontend/Vendor/shop/theme.xml package-source/vendor/magento2-theme-b2b/theme.xml
  make_package app/design/frontend/Vendor/shop/web/tailwind build watch
  make_package package-source/vendor/magento2-theme-b2b build watch
  make_package package-source/vendor/magento2-module build watch
}

@test "builds every theme, but no module, without a target" {
  run mage_cmd_build
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm --prefix app/design/frontend/Vendor/shop/web/tailwind run build"* ]]
  [[ "$output" == *"npm --prefix package-source/vendor/magento2-theme-b2b run build"* ]]
  [[ "$output" != *"magento2-module"* ]]
}

@test "builds what matches a target, modules included" {
  run mage_cmd_build MODULE
  [ "$output" = "$(printf 'Running %s in package-source/vendor/magento2-module\nnpm --prefix package-source/vendor/magento2-module run build' "'build'")" ]
}

@test "skips a package without the script" {
  make_package app/design/frontend/Vendor/shop/web/tailwind watch

  run mage_cmd_build
  [[ "$output" != *"Vendor/shop"* ]]
}

@test "uses the configured script names" {
  MAGE_BUILD_SCRIPT="build-prod"
  make_package app/design/frontend/Vendor/shop/web/tailwind build-prod

  run mage_cmd_build shop
  [[ "$output" == *"npm --prefix app/design/frontend/Vendor/shop/web/tailwind run build-prod"* ]]
}

@test "builds the build.themes of mage.config.json without a target" {
  mkdir -p app/design/frontend/Vendor/other
  touch app/design/frontend/Vendor/other/theme.xml
  make_package app/design/frontend/Vendor/other/web/tailwind build watch
  echo '{ "build": { "themes": ["shop", "Vendor/shop/web", "b2b"] } }' > mage.config.json

  run mage_cmd_build
  [ "$status" -eq 0 ]
  [ "$(grep -c 'run build' <<< "$output")" -eq 2 ]
  [[ "$output" == *"npm --prefix app/design/frontend/Vendor/shop/web/tailwind run build"* ]]
  [[ "$output" == *"npm --prefix package-source/vendor/magento2-theme-b2b run build"* ]]
  [[ "$output" != *"Vendor/other"* ]]
}

@test "a target goes before the build.themes of mage.config.json" {
  echo '{ "build": { "themes": ["shop"] } }' > mage.config.json

  run mage_cmd_build b2b
  [ "$status" -eq 0 ]
  [[ "$output" == *"magento2-theme-b2b run build"* ]]
  [[ "$output" != *"Vendor/shop"* ]]
}

@test "fails on a theme of mage.config.json that matches nothing" {
  echo '{ "build": { "themes": ["shop", "missing"] } }' > mage.config.json

  run mage_cmd_build
  [ "$status" -eq 1 ]
  [[ "$output" == *"matches 'missing' of the build.themes in mage.config.json"* ]]
  [[ "$output" != *"npm"* ]]
}

@test "fails on a build of mage.config.json without a list of themes" {
  echo '{ "build": ["shop"] }' > mage.config.json

  run mage_cmd_build
  [ "$status" -eq 1 ]
  [[ "$output" == *"should hold a list of themes"* ]]
}

@test "builds every theme with a mage.config.json without a build" {
  echo '{ "test": ["true"] }' > mage.config.json

  run mage_cmd_build
  [ "$status" -eq 0 ]
  [[ "$output" == *"Vendor/shop/web/tailwind run build"* ]]
  [[ "$output" == *"magento2-theme-b2b run build"* ]]
}

@test "watches one of the build.themes of mage.config.json without a target" {
  echo '{ "build": { "themes": ["shop", "b2b"] } }' > mage.config.json

  run mage_cmd_build --watch <<< "2"
  [ "${lines[${#lines[@]}-1]}" = "npm --prefix package-source/vendor/magento2-theme-b2b run watch" ]
}

@test "watching needs a target" {
  run mage_cmd_build --watch
  [ "$status" -eq 1 ]
  [[ "$output" == *"Watching needs a target"* ]]
}

@test "watches the one match of a target" {
  run mage_cmd_build shop --watch
  [ "$output" = "$(printf 'Running %s in app/design/frontend/Vendor/shop/web/tailwind\nnpm --prefix app/design/frontend/Vendor/shop/web/tailwind run watch' "'watch'")" ]
}

@test "asks which to watch when a target matches more" {
  run mage_cmd_build vendor -w <<< "2"
  [[ "$output" == *"npm --prefix package-source/vendor/magento2-module run watch"* ]]

  run mage_cmd_build vendor -w <<< "9"
  [ "$status" -eq 1 ]
}

@test "installs the packages first when they are missing" {
  rm -rf app/design/frontend/Vendor/shop/web/tailwind/node_modules

  run mage_cmd_build shop
  [[ "$output" == *"npm --prefix app/design/frontend/Vendor/shop/web/tailwind install"* ]]

  touch app/design/frontend/Vendor/shop/web/tailwind/package-lock.json
  run mage_cmd_build shop
  [[ "$output" == *"npm --prefix app/design/frontend/Vendor/shop/web/tailwind ci"* ]]
}

@test "builds the Hyva theme in vendor, the CSP one when installed" {
  mkdir -p vendor/hyva-themes/magento2-default-theme/web/tailwind/node_modules

  run mage_cmd_build hyva
  [[ "$output" == *"npm --prefix vendor/hyva-themes/magento2-default-theme/web/tailwind run build"* ]]

  mkdir -p vendor/hyva-themes/magento2-default-theme-csp/web/tailwind/node_modules
  run mage_cmd_build hyva --watch
  [[ "$output" == *"npm --prefix vendor/hyva-themes/magento2-default-theme-csp/web/tailwind run watch"* ]]
}
