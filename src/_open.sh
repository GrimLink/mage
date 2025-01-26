function mage_open() {
  local store=$2
  local store_url=$(get_mage_store_uri ${store:-1})
  local admin_path=""

  # Prefetch admin URL data for open steps
  if [[ "$store" == "admin" ]]; then
    local admin_path=$(grep frontName app/etc/env.php | tail -1 | cut -d '>' -f2 | cut -d '"' -f2 | cut -d "'" -f2)
  fi

  if [[ -z "$store_url" ]]; then
    echo "Could not find url for store $store"
  else
    echo -e "Opening: ${store_url}${admin_path}"
    $OPEN_CLI ${store_url}${admin_path}
  fi
}

function mage_open_editor() {
  case $EDITOR in
  "phpstorm")
    echo "Opening PHPStorm.."; phpstorm .
    ;;

  "code" | "code -w" | "code --wait")
    echo "Opening VSCode.."; code .
    ;;

  "zed" | "zed -w" | "zed --wait")
    echo "Opening Zed.."; zed .
    ;;

  "subl" | "subl -w" | "subl --wait")
    echo "Opening Sublime Text.."; subl .
    ;;

  "*")
    echo "No valid EDITOR found"
    ;;
  esac;
}

function mage_open_gitclient() {
  if [ -d .git ]; then
    if command -v github &>/dev/null; then
      echo "Opening Github Desktop.."; github .;
    elif command -v fork &>/dev/null; then
      echo "Opening Fork.."; fork;
    elif command -v gittower &>/dev/null; then
      echo "Opening Gittower.."; gittower;
    fi
  fi
}
