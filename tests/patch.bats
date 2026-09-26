load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="echo composer"
  mkdir -p vendor/cweagans/composer-patches
}

@test "adds a patch entry and applies it" {
  run mage_cmd_add patch magento/module-theme Fix the header patches/header
  [ "$status" -eq 0 ]
  [ "$(jq -r '.patches["magento/module-theme"]["Fix the header"]' patches.json)" = "patches/header.patch" ]
  [[ "$output" == *"composer patches-relock"*"composer patches-repatch"* ]]
}

@test "keeps a url as the patch source" {
  mage_cmd_add patch vendor/package Name https://example.com/fix.diff > /dev/null

  [ "$(jq -r '.patches["vendor/package"].Name' patches.json)" = "https://example.com/fix.diff" ]
}

@test "asks for what is not given" {
  mage_cmd_add patch <<< "$(printf 'vendor/package\nName\npatches/fix.patch')" > /dev/null 2>&1

  [ "$(jq -r '.patches["vendor/package"].Name' patches.json)" = "patches/fix.patch" ]
}

@test "keeps the existing patches" {
  echo '{ "patches": { "vendor/package": { "Old": "patches/old.patch" } } }' > patches.json

  mage_cmd_add patch vendor/package New patches/new.patch > /dev/null

  [ "$(jq -r '.patches["vendor/package"] | keys | join(",")' patches.json)" = "New,Old" ]
}

@test "merges the patches of a repository folder" {
  echo '{ "patches": { "vendor/package": { "Old": "patches/old.patch" } } }' > patches.json
  mkdir -p repo/patches/vendor
  echo '{ "patches": { "vendor/package": { "Repo": "patches/vendor/repo.patch" } } }' > repo/patches.json
  touch repo/patches/vendor/repo.patch

  run mage_add_patch_folder repo
  [ "$status" -eq 0 ]
  [ -f patches/vendor/repo.patch ]
  [ "$(jq -r '.patches["vendor/package"] | keys | join(",")' patches.json)" = "Old,Repo" ]
}

@test "errors without composer patches" {
  rm -rf vendor/cweagans

  run mage_cmd_add patch vendor/package Name patches/fix.patch
  [ "$status" -eq 1 ]
  [[ "$output" == *"mage add cweagans/composer-patches"* ]]
}

@test "adds the bfcache patches from their repository" {
  function mage_add_patch() { echo "patch $*"; }

  run mage_cmd_add bfcache
  [ "$output" = "patch https://github.com/GrimLink/magento-patch-bfcache" ]
}
