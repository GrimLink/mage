MAGE_SHOW_HANDLERS+=("fpc|Show the full page cache in use, builtin or varnish")

function mage_show_fpc() {
  local application
  application="$($MAGENTO_CLI config:show system/full_page_cache/caching_application 2> /dev/null)"

  case "$application" in
    "" | "1") mage_info "builtin" ;;
    "2") mage_info "varnish" ;;
    *) mage_info "$application" ;;
  esac
}
