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

@test "asks for the name when only a package and source are given" {
  mage_cmd_add patch vendor/package patches/fix <<< "Name" > /dev/null 2>&1

  [ "$(jq -r '.patches["vendor/package"].Name' patches.json)" = "patches/fix.patch" ]
}

@test "creates a patch from the changes in the vendor folder, new files included" {
  mkdir -p vendor/vendor/package
  echo "old" > vendor/vendor/package/file.php
  echo "untouched" > vendor/vendor/package/other.php
  function mage_patch_wait_for_changes() {
    echo "new" > "$1/file.php"
    echo "added" > "$1/added.php"
  }

  run mage_cmd_add patch vendor/package
  [ "$status" -eq 0 ]

  local patch="patches/vendor/package/LOCAL-vendor-package.patch"
  grep -q "^-old" "$patch"
  grep -q "^+new" "$patch"
  grep -q "^+added" "$patch"
  grep -q "a/file.php" "$patch"

  run grep -q "other.php" "$patch"
  [ "$status" -eq 1 ]
  [ ! -e vendor/vendor/package/.git ]
  [ "$(jq -r '.patches["vendor/package"]["Local: vendor-package"]' patches.json)" = "$patch" ]
  [[ "$output" == *"composer patches-repatch"* ]]
}

@test "numbers a second local patch of the same package" {
  mkdir -p vendor/vendor/package patches/vendor/package
  touch patches/vendor/package/LOCAL-vendor-package.patch
  function mage_patch_wait_for_changes() { echo "change" > "$1/file.php"; }

  mage_cmd_add patch vendor/package > /dev/null 2>&1

  [ -s patches/vendor/package/LOCAL-vendor-package-2.patch ]
  [ "$(jq -r '.patches["vendor/package"]["Local: vendor-package 2"]' patches.json)" = "patches/vendor/package/LOCAL-vendor-package-2.patch" ]
}

@test "creates no patch without changes" {
  mkdir -p vendor/vendor/package
  echo "same" > vendor/vendor/package/file.php
  function mage_patch_wait_for_changes() { :; }

  run mage_cmd_add patch vendor/package
  [ "$status" -eq 1 ]
  [ ! -e patches/vendor/package/LOCAL-vendor-package.patch ]
  [ ! -e vendor/vendor/package/.git ]
}

@test "refuses a package that is a git repository" {
  mkdir -p vendor/vendor/package/.git

  run mage_cmd_add patch vendor/package
  [ "$status" -eq 1 ]
  [ -d vendor/vendor/package/.git ]
}

@test "refuses a package linked from a path repository" {
  mkdir -p package-source/vendor/package vendor/vendor
  ln -s ../../package-source/vendor/package vendor/vendor/package

  run mage_cmd_add patch vendor/package
  [ "$status" -eq 1 ]
  [[ "$output" == *"links to a local package"* ]]
  [ ! -e package-source/vendor/package/.git ]
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

  run mage_patch_merge repo
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
