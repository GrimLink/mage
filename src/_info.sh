MAGE_VERSION="2.3.4"

function mage_version() {
  echo -e "\n${BOLD}Mage ${GREEN}${MAGE_VERSION}${RESET}, ${ITALIC}See https://github.com/GrimLink/mage for the latest version${RESET}\n"
}

function mage_help_cmd() {
  echo -e "- ${BLUE}${1}${RESET} (${2})"
}

function mage_help() {
  echo -e "${BOLD}Available commands:${RESET}"

  mage_help_cmd "self-update"                           "Update mage"
  mage_help_cmd "info"                                  "Show base config for store"

  mage_help_cmd "start"                                 "Open store and admin with code editor and git client"
  mage_help_cmd "open"                                  "Open default store view"
  mage_help_cmd "open admin"                            "Open store admin"
  mage_help_cmd "open [storeview]"                      "Open specific store view"
  mage_help_cmd "stores"                                "Show all stores"

  mage_help_cmd "watch"                                 "Run cache-clean.js from mageTV"
  mage_help_cmd "browser-sync"                          "Run browser-sync on default store view"
  mage_help_cmd "browser-sync [storeview]"              "Run browser-sync on specific store view"

  mage_help_cmd "reindex"                               "Reindex all indexes and clear cache"
  mage_help_cmd "purge"                                 "Purge all static assets"

  mage_help_cmd "new admin"                             "Create new admin user"
  mage_help_cmd "new customer"                          "Create new customer"
  mage_help_cmd "new theme"                             "Create new theme"
  mage_help_cmd "new module"                            "Create new module"
  mage_help_cmd "new patch"                             "Create new patch"
  mage_help_cmd "new i18n [src] | new translate [src]"  "Create new translations"

  mage_help_cmd "add patch"                             "Add patch"
  mage_help_cmd "add sample"                            "Add sample data"
  mage_help_cmd "add hyva"                              "Add Hyva Theme"
  mage_help_cmd "add checkout"                          "Add Hyva Checkout"
  mage_help_cmd "add baldr"                             "Add Siteation Baldr"

  mage_help_cmd "set mage-os"                           "Replace Magento2 with Mage-OS distro"
  mage_help_cmd "set theme [theme]"                     "Run yireo theme:change"
  mage_help_cmd "set hyva"                              "Set theme: Hyva default"
  mage_help_cmd "set baldr"                             "Set theme: Siteation Baldr"
  mage_help_cmd "set mode [mode]"                       "Set deploy mode with admin settings for dev or prod"
  mage_help_cmd "set countries [list_countries]"        "Set the store countries"
  mage_help_cmd "set fsp | set fpc default"             "Set the full page cache to system"
  mage_help_cmd "set fpc varnish"                       "Set the full page cache to varnish"
  mage_help_cmd "set csp"                               "Enable CSP mode for Magento"

  mage_help_cmd "log | log debug"                       "watch the debug log"
  mage_help_cmd "log exception"                         "watch the exception log"
  mage_help_cmd "log system"                            "watch the system log"

  mage_help_cmd "outdated"                              "Show all direct outdated composer dependencies"
  mage_help_cmd "build"                                 "Run setup:static-content:deploy with common defaults"
  mage_help_cmd "run"                                   "Run magerun2"

  echo -e "\n${ITALIC}Anything else will run ${BLUE}bin/magento${RESET}, ${ITALIC}To view this again, run ${BLUE}mage help${RESET}"
}

function mage_info() {
  echo -e "Magento: $GREEN$($MAGENTO_CLI --version | sed 's/Magento CLI //')$RESET"

  if $COMPOSER_CLI show hyva-themes/magento2-default-theme > /dev/null 2>&1; then
    local hyva_version="$(get_composer_pkg_version 'hyva-themes/magento2-theme-module')"
    local hyva_theme_version="$(get_composer_pkg_version 'hyva-themes/magento2-default-theme')"
    echo -e "Hyva: $GREEN$hyva_version$RESET"
    if [ "$hyva_version" != "$hyva_theme_version" ]; then
      echo -e " - Theme: $GREEN$hyva_theme_version$RESET"
    fi
    echo -e " - Modules: $($MAGENTO_CLI module:status | grep 'Hyva_' | sed 's/Hyva_//g' | paste -sd ',')"
  fi

  echo -e "PHP: $GREEN$($PHP_CLI --version | grep ^PHP | cut -d' ' -f2)$RESET"
  echo -e "NODE: $GREEN$($NODE_CLI --version | sed 's/v//')$RESET"
  echo -e "Base URI: $(get_mage_base_uri)"
  echo -e "Admin URI: $(grep frontName app/etc/env.php | tail -1 | cut -d ">" -f2 | cut -d "'" -f2)"
  echo -e "Database: $(grep dbname app/etc/env.php | tail -1 | cut -d ">" -f2 | cut -d "'" -f2)"
  $MAGENTO_CLI deploy:mode:show
  $MAGENTO_CLI maintenance:status
  if [[ -n "$MAGENTO_CLI config:show catalog/search/engine" ]]; then
    echo -e "Search Engine: $($MAGENTO_CLI config:show catalog/search/engine)"
  fi
}
