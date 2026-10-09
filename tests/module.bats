load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  echo '{}' > composer.json
}

@test "creates a module in app/code by its namespace" {
  mage_add_module Vendor/MyModule --no-hyva <<< "n" 2> /dev/null

  local dest="app/code/Vendor/MyModule"
  [ -f "${dest}/etc/module.xml" ]
  [ -f "${dest}/.gitignore" ]
  grep -q "'Vendor_MyModule'" "${dest}/registration.php"
  grep -q '<module name="Magento_Theme"/>' "${dest}/etc/module.xml"
  grep -q '"vendor/magento2-my-module"' "${dest}/composer.json"
  grep -q '"Vendor\\\\MyModule\\\\": ""' "${dest}/composer.json"
  [ ! -e "${dest}/Observer" ]

  run grep -rq "{{" "$dest"
  [ "$status" -eq 1 ]
}

@test "adds the Hyva files to a Hyva module" {
  mage_add_module Vendor/MyModule --hyva <<< "n" 2> /dev/null

  local dest="app/code/Vendor/MyModule"
  grep -q '<module name="Hyva_Theme"/>' "${dest}/etc/module.xml"
  grep -q "namespace Vendor\\\\MyModule\\\\Observer;" "${dest}/Observer/RegisterModuleForHyvaConfig.php"
  [ -f "${dest}/etc/frontend/events.xml" ]
  [ -f "${dest}/view/frontend/tailwind/module.css" ]
}

@test "asks about Hyva, defaulting to yes when it is installed" {
  mkdir -p vendor/hyva-themes/magento2-theme-module

  mage_add_module Vendor/MyModule <<< "$(printf '\nn')" 2> /dev/null

  [ -f app/code/Vendor/MyModule/Observer/RegisterModuleForHyvaConfig.php ]
}

@test "creates and requires a module in package-source" {
  run mage_add_module Vendor/MyModule --no-hyva <<< "y"

  [ -f package-source/vendor/magento2-my-module/registration.php ]
  [[ "$output" == *"composer require vendor/magento2-my-module:@dev"* ]]
}

@test "refuses a name that is not a valid namespace" {
  run mage_add_module Vendor/my-module --no-hyva <<< "n"
  [ "$status" -eq 1 ]
  [ ! -e app/code ]
}

@test "refuses an existing module" {
  mkdir -p app/code/Vendor/MyModule

  run mage_add_module Vendor/MyModule --no-hyva <<< "n"
  [ "$status" -eq 1 ]
}
