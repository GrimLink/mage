MAGE_CLEAN_HANDLERS+=("varnish|Ban all pages from Varnish, skipped without varnishadm")

function mage_clean_varnish() {
  if ! command -v "${VARNISH_CLI%% *}" &> /dev/null; then
    return 0
  fi

  $VARNISH_CLI 'ban req.url ~ .' &> /dev/null
  mage_check $? "Varnish"
}
