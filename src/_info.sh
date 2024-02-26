MAGE_VERSION="1.20.0"

function mage_version() {
  echo -e "\n${BOLD}Mage ${GREEN}${MAGE_VERSION}${RESET}"
  echo -e "${ITALIC}See https://github.com/GrimLink/mage for the last version${RESET}\n"
}

function mage_help_cmd() {
  echo -e "- ${BLUE}${1}${RESET} (${2})"
}

function mage_help() {
  echo -e "${BOLD}CMD Options:${RESET}"
  mage_help_cmd "self-update"       "Update mage"
  mage_help_cmd "info"              "Show base config for store"
  mage_help_cmd "stores"            "Show all stores"
  mage_help_cmd "open"              "Open default store view"
  mage_help_cmd "open admin"        "Open store admin"
  mage_help_cmd "open [storeview]"  "Open specific store view"
  mage_help_cmd "watch"             "Run cache-clean.js from mageTV"
  mage_help_cmd "browser-sync"      "Run browser-sync on the default store view"
  mage_help_cmd "reindex"           "Reindex all indexes and clear cache"
  mage_help_cmd "purge"             "Purge all static assets"
  mage_help_cmd "new admin"         "Create new admin user"
  mage_help_cmd "new customer"      "Create new customer"
  mage_help_cmd "new theme"         "Create new theme"
  mage_help_cmd "new module"        "Create new module"
  mage_help_cmd "new i18n"          "Create new translations"
  mage_help_cmd "add sample"        "Add sample data"
  mage_help_cmd "add hyva"          "Add Hyvä Theme"
  mage_help_cmd "add checkout"      "Add Hyvä Checkout"
  mage_help_cmd "set theme"         "Set theme"
  mage_help_cmd "set hyva"          "Set Hyvä default theme"
  mage_help_cmd "set baldr"         "Set Siteation Baldr theme"
  mage_help_cmd "set config"        "Set Magento Configs"
  mage_help_cmd "build"             "Run setup:static-content:deploy with common defaultsv"
  mage_help_cmd "run"               "Run magerun2"
  echo -e "\n${ITALIC}Anything else will run ${BLUE}bin/magento${RESET}"
  echo -e "${ITALIC}To see these copmmand again, run ${BLUE}mage help${RESET}"
}