MAGE_CLEAN_HANDLERS+=("opensearch|Delete the OpenSearch indices of this project, reindex afterwards")

# Delete the search indices of the project, using the OpenSearch config from
# Magento, so during a nuke this has to run before the database is dropped.
# The optional argument is the prefix to use when Magento has none.
function mage_clean_opensearch() {
  local host="$MAGE_SEARCH_HOST"
  local port="$MAGE_SEARCH_PORT"
  local prefix="$1"
  local line

  while IFS= read -r line; do
    case "$line" in
      "catalog/search/opensearch_server_hostname - "*) host="${line#* - }" ;;
      "catalog/search/opensearch_server_port - "*) port="${line#* - }" ;;
      "catalog/search/opensearch_index_prefix - "*) prefix="${line#* - }" ;;
    esac
  done < <($MAGENTO_CLI config:show catalog/search 2> /dev/null)

  if [[ -z "$prefix" ]]; then
    mage_check 1 "Could not determine the OpenSearch index prefix"
    return 1
  fi

  $SEARCH_CURL_CLI -fs -X DELETE "${host}:${port}/${prefix}_*" > /dev/null
  mage_check $? "OpenSearch indices with prefix '${prefix}_'"
}
