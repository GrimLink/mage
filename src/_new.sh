function mage_new_in_folder() {
  if [[ ! -d package-source ]]; then
    mkdir package-source
  fi

  read -p "Create in package-source as local composer package? [y/N] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    echo "package-source";
  else
    echo $1
  fi;
}

function mage_new_theme() {
  local application="frontend"
  local default_parrent_theme="Hyva/default"

  read -p "Is this a admin theme? [y/N] "
  echo ""
  if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
    local application="adminhtml"
  fi;

  local dest_path=$(mage_new_in_folder "app/design/${application}")

  read -p "Theme Name: " theme_name
  if [[ -z "$theme_name" ]]; then echo "The 'Name' can not be empty" && exit 1; fi

  if [[ "$theme_name" == */* ]]; then
    local theme_vendor="${theme_name%%/*}"
    local theme_name="${theme_name#*\/}"
  else
    read -p "Theme Vendor: " theme_vendor
    if [[ -z "$theme_vendor" ]]; then echo "The 'vendor' can not be empty" && exit 1; fi
  fi

  read -p "Parrent Theme ($default_parrent_theme): " parrent_theme
  if [[ -z "$parrent_theme" ]]; then parrent_theme=$default_parrent_theme; fi

  local theme_vendor="$(echo "$theme_vendor" | tr -d '[:blank:]')"
  local theme_name="$(echo "$theme_name" | tr -d '[:blank:]')"
  local folder_name="${theme_vendor}/$(mage_kebab_case "$theme_name")"

  local dest_path="$dest_path/$folder_name"
  local file_registration="<?php declare(strict_types=1);\n\nuse Magento\Framework\Component\ComponentRegistrar;\n\nComponentRegistrar::register(ComponentRegistrar::THEME, '${application}/${folder_name}', __DIR__);"
  local file_xml="<theme\n\txmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n\txsi:noNamespaceSchemaLocation=\"urn:magento:framework:Config/etc/theme.xsd\"\n>\n\t<title>${theme_vendor} ${theme_name}</title>\n\t<parent>${parrent_theme}</parent>\n</theme>"

  mkdir -p $dest_path
  if [[ $parrent_theme == Hyva/* ]]; then
    mkdir -p $dest_path/web/tailwind
    mage_make_file $dest_path/web/tailwind rsync vendor/hyva-themes/magento2-default-theme/web/tailwind
  fi

  mage_make_file $dest_path/registration.php "${file_registration}"
  mage_make_file $dest_path/theme.xml "${file_xml}"
}

function mage_new_module() {
  local dest_path=$(mage_new_in_folder "app/code")

  read -p "Module Name: " module_name
  if [[ -z "$module_name" ]]; then echo "The 'Name' can not be empty" && exit 1; fi

  if [[ "$module_name" == */* ]]; then
    local module_vendor="${module_name%%/*}"
    local module_name="${module_name#*\/}"
  else
    read -p "Module Vendor: " module_vendor
    if [[ -z "$module_vendor" ]]; then echo "The 'vendor' can not be empty" && exit 1; fi
  fi

  local module_vendor="$(echo "$module_vendor" | tr -d '[:blank:]')"
  local module_name="$(echo "$module_name" | tr -d '[:blank:]')"
  local folder_name="${module_vendor}/$(mage_kebab_case "$module_name")"

  local dest_path="$dest_path/$folder_name"
  local file_registration="<?php declare(strict_types=1);\n\nuse Magento\Framework\Component\ComponentRegistrar;\n\nComponentRegistrar::register(ComponentRegistrar::MODULE, '${module_vendor}_${module_name}', __DIR__);"
  local file_xml="<?xml version=\"1.0\"?>\n<config\n\txmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n\txsi:noNamespaceSchemaLocation=\"urn:magento:framework:Module/etc/module.xsd\"\n>\n\t<module name=\"${module_vendor}_${module_name}\">\n\t\t<sequence>\n\t\t\t<module name=\"Magento_Theme\"/>\n\t\t</sequence>\n\t</module>\n</config>"

  mkdir -p $dest_path/etc
  mage_make_file $dest_path/registration.php "${file_registration}"
  mage_make_file $dest_path/etc/module.xml "${file_xml}"
}
