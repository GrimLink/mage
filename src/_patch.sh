
function mage_add_patch() {
  local vendor="${1}";
  local patch_src="${@: -1}";
  local patch_name="${@:2:$#-2}";

  if [[ -z "$vendor" ]]; then
    echo "The vendor your patching, Example: magento/module-theme or hyva-themes/magento_theme"
    read -e -p "Vendor Name: " vendor && echo ""
  fi

  if [[ -z "$patch_name" ]]; then
    read -e -p "Patch Name: " patch_name && echo ""
  fi

  if [[ -z "$patch_src" ]]; then
    echo "The source to patches/FOLDER or a git raw url"
    read -e -p "Patch Source: " patch_src && echo ""
  fi

  if [[ ! "$patch_src" =~ ^https:// && "${patch_src: -6}" != ".patch" ]]; then
    patch_src="${patch_src%.*}.patch"
  fi

  # Ensure composer.json is configured to use composer.patches.json
  if ! grep -q '"patches-file": "composer.patches.json"' composer.json;
  then
    $COMPOSER_CLI config extra.patches-file composer.patches.json
  fi

  # Create composer.patches.json if it doesn't exist
  if [[ ! -f "composer.patches.json" ]]; then
    echo '{ "patches": {} }' > composer.patches.json
  fi

  php -r '
    $file = "composer.patches.json";
    $vendor = $argv[1];
    $patch_name = $argv[2];
    $patch_src = $argv[3];

    $json = json_decode(file_get_contents($file), true);

    if (!isset($json["patches"])) {
        $json["patches"] = [];
    }

    if (!isset($json["patches"][$vendor])) {
        $json["patches"][$vendor] = [];
    }

    $json["patches"][$vendor][$patch_name] = $patch_src;

    file_put_contents($file, json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
  ' -- "$vendor" "$patch_name" "$patch_src"

  echo -e "Patch added to composer.patches.json"
}

function mage_new_patch() {
  local module_name=${1}

  if [[ -z "$module_name" ]]; then
    echo "The module you want to patch, Example: magento/module-theme"
    read -e -p "Module Name: " module_name && echo ""
  fi

  local module_src="vendor/${module_name}"

  if [[ ! -d "$module_src" ]]; then
    echo "Can not find $module_src make sure this is the right path" && exit 1;
  fi

  cd $module_src
  git init &> /dev/null
  git add .

  read -rsn1 -p "Make your changes in $module_src when ready, press any key to continue";
  echo "";

  local patch_name
  read -e -p "Patch Name (e.g., my-custom-patch): " patch_name
  if [[ -z "$patch_name" ]]; then
    echo "Patch name cannot be empty."
    return 1
  fi
  local patch_file_path="patches/${$module_name}/${patch_name}"

  local patch_file_dir=$(dirname "../../../$patch_file_path")

  mkdir -p "$patch_file_dir"
  touch "../../../${patch_file_path}.patch"
  git diff > "../../../${patch_file_path}.patch"

  # Cleanup
  git checkout . &> /dev/null
  rm -rf .git
  cd - &> /dev/null

  # Add composer patch setting
  read -p "Add patch to composer.json? [Y/n] "
  echo ""
  if [[ ! $REPLY =~ ^[nN]|[nN][oO]$ ]]; then
    # Vendor Folder / Patch Name / Patch Source
    mage_add_patch $module_name "Patch: ${patch_name}" "${patch_file_path}"
  fi;

  echo -e "Patch created in ${patch_file_path}.patch".
  echo "Make sure the patch and settings in composer.json are correct before running composer install"
}
