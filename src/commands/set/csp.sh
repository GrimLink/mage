MAGE_SET_HANDLERS+=("csp|Enforce a strict CSP on the storefront, no inline or eval scripts")

# Locked in app/etc/env.php, as a strict CSP is a choice of the codebase,
# such as a Hyva CSP theme, not a setting to change in the admin
function mage_set_csp() {
  $MAGENTO_CLI config:set --lock-env csp/mode/storefront/report_only 0 &&
    $MAGENTO_CLI config:set --lock-env csp/policies/storefront/scripts/inline 0 &&
    $MAGENTO_CLI config:set --lock-env csp/policies/storefront/scripts/eval 0 || exit 1

  $MAGENTO_CLI cache:clean config
}
