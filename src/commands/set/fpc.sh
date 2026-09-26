MAGE_SET_HANDLERS+=("fpc|Use the builtin full page cache, or with 'varnish' Varnish")

function mage_set_fpc() {
  local application

  case "${1:-builtin}" in
    "builtin") application=1 ;;
    "varnish") application=2 ;;
    *)
      mage_error "Unknown full page cache '$1', use builtin or varnish"
      exit 1
      ;;
  esac

  $MAGENTO_CLI config:set system/full_page_cache/caching_application "$application"
}
