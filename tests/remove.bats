load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  cat > composer.json <<'EOF'
{
  "require": {
    "php": "~8.3",
    "ext-hyva": "*",
    "hyva-themes/magento2-default-theme": "*",
    "vendor/magento2-Hyva-compat": "*",
    "siteation/magento2-storeinfo": "*",
    "magento/product-community-edition": "2.4.8"
  },
  "require-dev": {
    "hyva-themes/magento2-dev-tools": "*"
  }
}
EOF
}

@test "passes a package name as is to composer remove" {
  run mage_cmd_remove vendor/package --no-update
  [ "$output" = "composer remove vendor/package --no-update" ]
}

@test "removes the matches of a term after confirming" {
  run mage_cmd_remove hyva <<< "y"
  [[ "$output" == *"hyva-themes/magento2-dev-tools (dev)"* ]]
  [[ "$output" == *"composer remove hyva-themes/magento2-default-theme vendor/magento2-Hyva-compat"* ]]
  [[ "$output" == *"composer remove --dev hyva-themes/magento2-dev-tools"* ]]
  [[ "$output" != *"ext-hyva"* ]]
}

@test "removes nothing when not confirmed" {
  run mage_cmd_remove hyva <<< "n"
  [ "$status" -eq 0 ]
  [[ "$output" != *"composer remove"* ]]
}

@test "matches any of several terms, without asking with -y" {
  run mage_cmd_remove storeinfo community -y
  [[ "$output" == *"composer remove magento/product-community-edition siteation/magento2-storeinfo"* ]]
}

@test "matches terms as plain text" {
  run mage_cmd_remove "magento2-.*" -y
  [ "$status" -eq 1 ]
}

@test "errors without a match or arguments" {
  run mage_cmd_remove nothing-like-this
  [ "$status" -eq 1 ]

  run mage_cmd_remove
  [ "$status" -eq 1 ]
}
