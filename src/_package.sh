function mage_add_package() {
  local REQUIRE_ARGS=("${@}")

  if [[ "$1" == *".git" ]]; then
    local GIT_URL="$1"
    local TMP_DIR="package-source/tmp_clone_$$"

    echo "Cloning $GIT_URL..."
    git clone "$GIT_URL" "$TMP_DIR"

    local PACKAGE_NAME=""
    if [[ -f "$TMP_DIR/composer.json" ]]; then
      PACKAGE_NAME=$(get_composer_pkg_name_from_file "$TMP_DIR/composer.json")
    fi

    if [[ -z "$PACKAGE_NAME" ]]; then
      if [[ ! -f "$TMP_DIR/composer.json" ]]; then
        echo "Error: No composer.json found in the repository."
      else
        echo "Error: Could not parse package name from composer.json."
      fi
      REQUIRE_ARGS=()
    else
      local TARGET_DIR="package-source/$PACKAGE_NAME"

      if [[ -d "$TARGET_DIR" ]]; then
        echo "Warning: Directory $TARGET_DIR already exists."
        REQUIRE_ARGS=()
      else
        mkdir -p "$(dirname "$TARGET_DIR")"
        mv "$TMP_DIR" "$TARGET_DIR"

        echo "Requiring package $PACKAGE_NAME..."
        REQUIRE_ARGS=("$PACKAGE_NAME:@dev" "${@:2}")
      fi
    fi

    if [[ -d "$TMP_DIR" ]]; then
      echo "Removing temporary clone."
      rm -rf "$TMP_DIR"
    fi
  fi

  if [[ ${#REQUIRE_ARGS[@]} -gt 0 ]]; then
    $COMPOSER_CLI require "${REQUIRE_ARGS[@]}"
  fi
}
