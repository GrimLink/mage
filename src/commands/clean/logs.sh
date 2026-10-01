MAGE_CLEAN_HANDLERS+=("logs|Delete the logs in var/log")

function mage_clean_logs() {
  find var/log -maxdepth 1 -type f -name "*.log" -delete 2> /dev/null
  mage_check 0 "var/log/*.log"
}
