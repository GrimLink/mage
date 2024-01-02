# Vanila solution to get the Magento 2 base url
function get_mage_base_uri() {
  BASEURI="$($MAGENTO_CLI config:show web/secure/base_url)"
  if [[ -z "${BASEURI}" ]]; then
    BASEURI="$($MAGENTO_CLI config:show web/unsecure/base_url)"
  fi

  echo $BASEURI
}

function mage_open() {
  STORE=${2:-1}
  STORE_URL=""
  ADMIN_PATH=""

  # Prefetch admin URL data for open steps
  if [[ "$STORE" == "admin" ]]; then
    ADMIN_PATH=$(grep frontName app/etc/env.php | tail -1 | cut -d '>' -f2 | cut -d '"' -f2 | cut -d "'" -f2)
  fi

  # Fetch the store url
  if [[ -n "$MAGERUN_CLI" ]]; then
    if [[ "$STORE" == "admin" ]]; then
      STORE_URL=$($MAGERUN_CLI sys:store:config:base-url:list --format csv | grep 1 -m 1 | head -1 | cut -d ',' -f3)
    else
      STORE_URL=$($MAGERUN_CLI sys:store:config:base-url:list --format csv | grep $STORE | cut -d ',' -f3)
    fi
  else
    STORE_URL=$(get_mage_base_uri)
  fi

  if [[ -z "$STORE_URL" ]]; then
    echo "Could not find url for store $STORE"
  else
    echo -e "Opening: ${STORE_URL}${ADMIN_PATH}"
    $OPEN_CLI ${STORE_URL}${ADMIN_PATH}
  fi
}
