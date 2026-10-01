load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  echo '{}' > composer.json
}

@test "creates a child theme in app/design" {
  mage_add_theme Vendor/MyTheme --parent=Magento/blank <<< "n" 2> /dev/null

  local dest="app/design/frontend/Vendor/my-theme"
  [ -f "${dest}/theme.xml" ]
  [ -f "${dest}/.editorconfig" ]
  grep -q "<parent>Magento/blank</parent>" "${dest}/theme.xml"
  grep -q "'frontend/Vendor/my-theme'" "${dest}/registration.php"
  grep -q '"vendor/magento2-theme-my-theme"' "${dest}/composer.json"

  run grep -rq "{{" "$dest"
  [ "$status" -eq 1 ]
}

@test "asks for the vendor when the name has none" {
  mage_add_theme --parent=Magento/blank <<< "$(printf 'MyTheme\nVendor\nn')" 2> /dev/null

  [ -f app/design/frontend/Vendor/my-theme/theme.xml ]
}

@test "creates an admin theme" {
  mage_add_theme Vendor/Admin --admin --parent=Magento/backend <<< "n" 2> /dev/null

  grep -q "'adminhtml/Vendor/admin'" app/design/adminhtml/Vendor/admin/registration.php
}

@test "creates and requires a theme in package-source" {
  run mage_add_theme Vendor/MyTheme --parent=Magento/blank <<< "y"

  [ -f package-source/vendor/magento2-theme-my-theme/theme.xml ]
  [[ "$output" == *"composer require vendor/magento2-theme-my-theme:@dev"* ]]
}

@test "refuses an existing theme" {
  mkdir -p app/design/frontend/Vendor/my-theme

  run mage_add_theme Vendor/MyTheme --parent=Magento/blank <<< "n"
  [ "$status" -eq 1 ]
}

@test "suggests Hyva as parent when it is installed" {
  [ "$(mage_theme_default_parent frontend)" = "Magento/luma" ]

  mkdir -p "$MAGE_HYVA_THEME_DIR"
  [ "$(mage_theme_default_parent frontend)" = "Hyva/default" ]
  [ "$(mage_theme_default_parent adminhtml)" = "Magento/backend" ]
}

@test "copies the Hyva tailwind folder without node_modules" {
  mkdir -p "${MAGE_HYVA_THEME_DIR}/web/tailwind/node_modules"
  touch "${MAGE_HYVA_THEME_DIR}/web/tailwind/tailwind.config.js"

  mage_add_theme Vendor/MyTheme --parent=Hyva/default <<< "n" 2> /dev/null

  [ -f app/design/frontend/Vendor/my-theme/web/tailwind/tailwind.config.js ]
  [ ! -e app/design/frontend/Vendor/my-theme/web/tailwind/node_modules ]
}
