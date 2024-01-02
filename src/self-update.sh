function mage_self_update() {
  cd $(dirname "${BASH_SOURCE}") &&
  rm mage &&
  $GET_CLI https://raw.githubusercontent.com/GrimLink/mage/main/mage &&
  chmod +x mage
}
