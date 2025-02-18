function mage_add_patch() {
  local vendor=${1};
  local patch_name=${2};
  local patch_src=${3};

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

  if [[ ! "$patch_src" =~ ^https:// ]]; then
    local patch_src="${patch_src%.*}.patch"
  fi

  $COMPOSER_CLI config extra.patches.$vendor -j "{ \"$patch_name\": \"$patch_src\" }"
  echo -e "Patch added to the composer.json in extra.patches.$vendor_folder_name"
}

function mage_new_patch_branch_diff() {
  git diff $(git rev-parse --abbrev-ref origin/HEAD)..$(git branch --show-current) > $(git branch --show-current).patch
}

function mage_new_patch_file() {
  local src=${1}

  # Remove leading slash
  if [[ $src == /* ]]; then src="${src:1}"; fi

  if [[ ! -f "$src" ]]; then
    echo "Can not find $src make sure this is the right path" && exit 1;
  fi

  # Get the module src for the temp git dir
  local module_src=$(echo "$src" | cut -d '/' -f -3)
  local file_src=$(echo "$src" | cut -d '/' -f 4-)
  local patched_file_src="${src%.*}.patch"

  cd $module_src
  git init &> /dev/null
  git add $file_src

  local patch_file_dir=$(dirname "patches/$patched_file_src")

  read -rsn1 -p "Make your changes in $src when ready, press any key to continue";
  echo "";

  mkdir -p "../../../$patch_file_dir"
  touch "../../../patches/$patched_file_src"
  git diff > "../../../patches/$patched_file_src"

  # Cleanup
  git checkout . &> /dev/null
  rm -rf .git
  cd - &> /dev/null

  # Add composer patch setting

  read -p "Add patch to composer.json? [Y/n] "
  echo ""
  if [[ ! $REPLY =~ ^[nN]|[nN][oO]$ ]]; then
    local vendor_folder_name=$(echo "$module_src" | sed 's/^vendor\///')
    # Vendor Folder / Patch Name / Patch Source
    mage_add_patch $vendor_folder_name "Patch: ${file_src}" "patches/${src}"
  fi;

  echo -e "Patch created in $patched_file_src".
  echo "Make sure the patch and settings in composer.json are correct before running composer install"
}
