MAGE_VERSION="2.0.0"

function mage_version() {
  echo -e "\n${BOLD}Mage ${GREEN}${MAGE_VERSION}${RESET}"
  echo -e "${ITALIC}See https://github.com/GrimLink/mage for the last version${RESET}\n"
}

function mage_help_cmd() {
  echo -e "- ${BLUE}${1}${RESET} (${2})"
}

function mage_help() {
  echo -e "${BOLD}CMD Options:${RESET}"

  mage_help_cmd "self-update"                     "Update mage"
  mage_help_cmd "info"                            "Show base config for store"
  mage_help_cmd "stores"                          "Show all stores"
  mage_help_cmd "open"                            "Open default store view"
  mage_help_cmd "open admin"                      "Open store admin"
  mage_help_cmd "open [storeview]"                "Open specific store view"
  mage_help_cmd "watch"                           "Run cache-clean.js from mageTV"
  mage_help_cmd "browser-sync"                    "Run browser-sync on default store view"
  mage_help_cmd "browser-sync [storeview]"        "Run browser-sync on specific store view"
  mage_help_cmd "reindex"                         "Reindex all indexes and clear cache"
  mage_help_cmd "purge"                           "Purge all static assets"
  mage_help_cmd "new admin"                       "Create new admin user"
  mage_help_cmd "new customer"                    "Create new customer"
  mage_help_cmd "new theme"                       "Create new theme"
  mage_help_cmd "new module"                      "Create new module"
  mage_help_cmd "new i18n | new translate [src]"  "Create new translations"
  mage_help_cmd "add sample"                      "Add sample data"
  mage_help_cmd "add hyva"                        "Add Hyva Theme"
  mage_help_cmd "add checkout"                    "Add Hyva Checkout"
  mage_help_cmd "add baldr"                       "Add Siteation Baldr"
  mage_help_cmd "set theme [theme]"               "Run yireo theme:change"
  mage_help_cmd "set hyva"                        "Set theme: Hyva default"
  mage_help_cmd "set baldr"                       "Set theme: Siteation Baldr"
  mage_help_cmd "set mode [mode]"                 "Run deploy:mode:set with admin settings for dev"
  mage_help_cmd "set countries [list_countries]"  "Set the store countries"
  mage_help_cmd "log | log debug"                 "watch the debug log"
  mage_help_cmd "log exception"                   "watch the exception log"
  mage_help_cmd "log system"                      "watch the system log"
  mage_help_cmd "build"                           "Run setup:static-content:deploy with common defaults"
  mage_help_cmd "run"                             "Run magerun2"

  echo -e "\n${ITALIC}Anything else will run ${BLUE}bin/magento${RESET}, ${ITALIC}To view this again, run ${BLUE}mage help${RESET}"
}
