function mage_open() {
  local store=$2
  local store_url=$(get_mage_store_uri ${store:-1})
  local admin_path=""

  # Prefetch admin URL data for open steps
  if [[ "$store" == "admin" ]]; then
    local admin_path=$(grep frontName app/etc/env.php | tail -1 | cut -d '>' -f2 | cut -d '"' -f2 | cut -d "'" -f2)
  fi

  if [[ -z "$store_url" ]]; then
    echo "Could not find url for store $store"
  else
    echo -e "Opening: ${store_url}${admin_path}"
    $OPEN_CLI ${store_url}${admin_path}
  fi
}

