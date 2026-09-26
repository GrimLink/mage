
function mage_add_patch() {
  local vendor="${1}"

  if [[ "$vendor" =~ ^https://(github|gitlab)\.com/ ]]; then
    local repo_url="${vendor%/}"
    local temp_dir=$(mktemp -d)
    local archive_url=""

    if [[ "$repo_url" =~ github\.com ]]; then
      archive_url="${repo_url}/tarball/main"
    else
      archive_url="${repo_url}/-/archive/main.tar.gz"
    fi

    echo "Downloading patches from $repo_url..."
    if ! curl -sL "$archive_url" | tar -xz -C "$temp_dir" --strip-components=1; then
       echo "Error: Failed to download repository from main branch."
       rm -rf "$temp_dir"
       return 1
    fi

    if [[ -f "$temp_dir/patches.json" ]]; then
       echo "Merging patches.json..."
       php -r '
         $l = file_exists("patches.json") ? json_decode(file_get_contents("patches.json"), true) : ["patches" => []];
         $r = json_decode(file_get_contents($argv[1]), true);
         foreach ($r["patches"] as $v => $ps) {
             foreach ($ps as $n => $s) $l["patches"][$v][$n] = $s;
         }
         file_put_contents("patches.json", json_encode($l, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
       ' "$temp_dir/patches.json"
    fi

    mkdir -p patches
    if [[ -d "$temp_dir/patches" ]]; then
       cp -R "$temp_dir/patches/"* patches/
    else
       cp -R "$temp_dir/"* patches/
    fi

    rm -rf "$temp_dir"
    echo "Patches successfully added and vendored."

    $COMPOSER_CLI patches-relock
    $COMPOSER_CLI patches-repatch
    return
  fi

  local patch_src=""
  local patch_name=""

  if [[ $# -ge 2 ]]; then
    patch_src="${@: -1}"
    patch_name="${@:2:$#-2}"
  fi

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

  # Create patches.json if it doesn't exist
  if [[ ! -f "patches.json" ]]; then
    echo '{ "patches": {} }' > patches.json
  fi

  php -r '
    $file = "patches.json";
    $vendor = $argv[1];
    $patch_name = $argv[2];
    $patch_src = $argv[3];

    $json = json_decode(file_get_contents($file), true);
    $json["patches"][$vendor][$patch_name] = $patch_src;
    file_put_contents($file, json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
  ' -- "$vendor" "$patch_name" "$patch_src"

  echo -e "Patch added to patches.json"

  $COMPOSER_CLI patches-relock
  $COMPOSER_CLI patches-repatch
}

function mage_new_patch() {
  local module_name="${1}"
  local module_src="vendor/${module_name}"

  if [[ -z "$module_name" ]]; then
    echo "The module you want to patch, Example: magento/module-theme"
    read -e -p "Module Name: " module_name && echo ""
    module_src="vendor/${module_name}"
  fi

  if [[ ! -d "$module_src" ]]; then
    echo "Can not find $module_src make sure this is the right path" && exit 1;
  fi

  if [[ -d "${module_src}/.git" ]]; then
    echo "Error: ${module_src} already contains a .git folder. Aborting to prevent data loss."
    exit 1
  fi

  cd $module_src
  git init &> /dev/null
  git add .

  read -rsn1 -p "Make your changes in $module_src when ready, press any key to continue";
  echo "";

  local module_filename=$(echo "$module_name" | tr '/' '-')
  local patch_filename="LOCAL-${module_filename}.patch"
  local patch_path="patches/${module_name}/${patch_filename}"

  # Move back to root for file operations
  cd - &> /dev/null

  mkdir -p "patches/${module_name}"
  git -C "$module_src" diff > "$patch_path"

  # Cleanup
  rm -rf "${module_src}/.git"

  echo -e "Patch created in ${patch_path}".

  # Add composer patch setting
  read -p "Add patch to composer.json? [Y/n] "
  echo ""
  if [[ ! $REPLY =~ ^[nN]|[nN][oO]$ ]]; then
    mage_add_patch "$module_name" "Local: ${module_filename}" "$patch_path"
  fi
}
