load helper

function setup() {
  load_mage
  cd "$BATS_TEST_TMPDIR"
  COMPOSER_CLI="fake_composer"
  MAGE_ROOT="$BATS_TEST_TMPDIR"
  MAGE_CALL_DIR="$BATS_TEST_TMPDIR"
}

@test "applies auth, repositories, config and packages in order" {
  cat > fragment.json <<'EOF'
{
  "description": "Example",
  "auth": { "http-basic": { "repo.example.com": { "username": "user", "password": "secret" } } },
  "repositories": { "example": { "type": "composer", "url": "https://repo.example.com/" } },
  "config": { "allow-plugins": { "vendor/plugin": true } },
  "require": { "vendor/a": "*", "vendor/b": "^1.0" },
  "require-dev": { "vendor/c": "dev-main" }
}
EOF

  run mage_cmd_add fragment.json
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "Adding Example" ]
  [[ "${lines[1]}" == "composer config --global --auth http-basic.repo.example.com user secret" ]]
  [[ "$output" == *'composer config --append repositories.example {"type":"composer","url":"https://repo.example.com/"}'* ]]
  [[ "$output" == *"composer config allow-plugins.vendor/plugin true"* ]]
  [[ "$output" == *"composer require vendor/a:* vendor/b:^1.0"* ]]
  [[ "$output" == *"composer require --dev vendor/c:dev-main"* ]]
}

@test "stores a token auth with its single value" {
  echo '{ "auth": { "gitlab-token": { "gitlab.example.com": "token" } } }' > fragment.json

  run mage_cmd_add fragment.json
  [[ "$output" == *"composer config --global --auth gitlab-token.gitlab.example.com token"* ]]
}

@test "fills placeholders from the answers" {
  echo '{ "repositories": { "private": { "type": "composer", "url": "https://repo/{{PROJECT}}/" } } }' > fragment.json

  run mage_cmd_add fragment.json <<< "my-project"
  [[ "$output" == *'"url":"https://repo/my-project/"'* ]]
}

@test "uses MAGE_VAR_ as the default answer" {
  echo '{ "auth": { "gitlab-token": { "gitlab.example.com": "{{TOKEN}}" } } }' > fragment.json
  MAGE_VAR_TOKEN="from-config"

  run mage_cmd_add fragment.json <<< ""
  [[ "$output" == *"gitlab-token.gitlab.example.com from-config"* ]]
}

@test "escapes answers for json" {
  echo '{ "repositories": { "private": { "type": "composer", "url": "{{URL}}" } } }' > fragment.json

  run mage_cmd_add fragment.json <<< 'a"b'
  [[ "$output" == *'"url":"a\"b"'* ]]
}

@test "errors on an empty answer" {
  echo '{ "require": { "vendor/{{NAME}}": "*" } }' > fragment.json

  run mage_cmd_add fragment.json <<< ""
  [ "$status" -eq 1 ]
}

@test "resolves the file from the calling folder" {
  mkdir -p nested
  echo '{ "require": { "vendor/a": "*" } }' > nested/fragment.json
  MAGE_CALL_DIR="${BATS_TEST_TMPDIR}/nested"

  run mage_cmd_add ./fragment.json
  [[ "$output" == *"composer require vendor/a:*"* ]]
}

@test "warns about unknown keys and config lists" {
  echo '{ "requires": {}, "config": { "list": ["a"] } }' > fragment.json

  run mage_cmd_add fragment.json
  [[ "$output" == *"Skipping the unknown key 'requires'"* ]]
  [[ "$output" == *"Skipping config 'list'"* ]]
}

@test "errors on a missing file or invalid json" {
  run mage_cmd_add missing.json
  [ "$status" -eq 1 ]

  echo '[1]' > list.json
  run mage_cmd_add list.json
  [ "$status" -eq 1 ]
}

@test "errors on repositories as a list" {
  echo '{ "repositories": [ { "type": "vcs", "url": "x" } ] }' > fragment.json

  run mage_cmd_add fragment.json
  [ "$status" -ne 0 ]
  [[ "$output" == *"object keyed by name"* ]]
}

@test "the bundled Hyva fragment applies with its placeholders" {
  MAGE_VAR_HYVA_PROJECT="acme"
  MAGE_VAR_HYVA_LICENSE_KEY="key"

  run mage_cmd_add "${MAGE_REPO}/templates/composer-hyva.json" <<< $'\n'
  [ "$status" -eq 0 ]
  [[ "$output" == *"--auth http-basic.hyva-themes.repo.packagist.com token key"* ]]
  [[ "$output" == *'"url":"https://hyva-themes.repo.packagist.com/acme/"'* ]]
  [[ "$output" == *"composer require hyva-themes/magento2-theme-module:* hyva-themes/magento2-default-theme:*"* ]]
}

@test "skips credentials the global auth already has, without asking for them" {
  FAKE_AUTH="http-basic.repo.example.com"
  echo '{ "auth": { "http-basic": { "repo.example.com": { "username": "token", "password": "{{SECRET}}" } } }, "require": { "vendor/a": "*" } }' > fragment.json

  run mage_cmd_add fragment.json < /dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"Using the http-basic credentials for repo.example.com from the global composer auth"* ]]
  [[ "$output" != *"composer config --global --auth http-basic.repo.example.com"* ]]
  [[ "$output" == *"composer require vendor/a:*"* ]]
}

@test "still asks for credentials of other hosts" {
  FAKE_AUTH="http-basic.other.example.com"
  echo '{ "auth": { "http-basic": { "repo.example.com": { "username": "token", "password": "{{SECRET}}" } } } }' > fragment.json

  run mage_cmd_add fragment.json <<< "key"
  [[ "$output" == *"composer config --global --auth http-basic.repo.example.com token key"* ]]
}
