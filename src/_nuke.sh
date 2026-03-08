function mage_nuke() {
  local MAGE_ROOT
  MAGE_ROOT=$(pwd)
  local DIR_NAME
  DIR_NAME=$(basename "$MAGE_ROOT")

  if [[ "$MAGE_ROOT" == "/" ]] || [[ "$DIR_NAME" == "/" ]] || [[ -z "$DIR_NAME" ]]; then
    echo "Error: Cannot nuke the system directory."
    return 1
  fi

  echo "WARNING: You are about to permanently delete the Magento environment in $MAGE_ROOT"
  read -p "Are you sure you want to proceed? [y/N] "
  echo ""

  if [[ ! $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    echo "Aborting nuke operation."
    return 0
  fi

  if [[ $VALET == 1 ]]; then
    echo "Detected Valet environment."
    echo "Dropping database: $DIR_NAME"
    mysql -u root -e "DROP DATABASE IF EXISTS \`$DIR_NAME\`;"

    echo "Unsecuring valet site..."
    valet unsecure

    if [ -f ".valet-env.php" ]; then
      local stores
      stores=$(php -r "if(file_exists('.valet-env.php')){ \$arr = include '.valet-env.php'; if(is_array(\$arr)){ foreach(array_keys(\$arr) as \$k) echo \$k . PHP_EOL; } }")
      for store in $stores; do
        if [[ "$store" != "$DIR_NAME" ]]; then
          echo "Unlinking and unsecuring extra store: $store"
          valet unsecure "$store"
          valet unlink "$store"
        fi
      done
    fi
  elif [[ $WARDEN == 1 ]]; then
    echo "Detected Warden environment."
    echo "Bringing down and destroying Warden environment..."
    warden env down -v
  fi

  echo "Removing directory: $MAGE_ROOT"
  cd ..
  rm -rf "$DIR_NAME"

  echo "Nuke complete."
}
