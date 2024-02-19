function mage_new_admin() {
  local SKIP="false"

  if [[ "$1" == "--yes" ]] || [[ "$1" == "-y" ]]; then
    local SKIP="true"
  fi

  if [[ $SKIP == "false" ]]; then
    read -p "Email (${GITEMAIL}) or: " USEREMAIL
    read -p "Firstname (${GITNAME}) or: " USERFIRST
    read -p "Lastname (admin) or: " USERLAST
    read -p "User name (${ADMINNAME}) or: " USERNAME
    read -sp "Password (${ADMINPASS}) or: " USERPASS
  fi

  $MAGENTO_CLI admin:user:create \
    --admin-user="${USERNAME:-$ADMINNAME}" \
    --admin-password="${USERPASS:-$ADMINPASS}" \
    --admin-email="${USEREMAIL:-$GITEMAIL}" \
    --admin-firstname="${USERFIRST:-$GITNAME}" \
    --admin-lastname="${USERLAST:-"admin"}"
}

function mage_new_translate() {
  local SRC=${3:-.}

  if [[ ! -f "$SRC/registration.php" ]]; then
    echo "This does not look like a Magento 2 module or theme"
    read -p "Are you sure if you want to continue? [y/N] "
    echo ""
    if [[ $REPLY =~ ^[yY]|[yY][eE][sS]$ ]]; then
      echo "Running '$MAGENTO_CLI i18n:collect-phrases' in '$SRC'"
    else
      exit 1
    fi;
  fi

  mkdir -p $SRC/i18n
  $MAGENTO_CLI i18n:collect-phrases $SRC -o $SRC/i18n/temp.csv
  sed -i '' -e 's/^\([^"].*\),\([^"].*\)$/"\1","\2"/' $SRC/i18n/temp.csv
  sort -o $SRC/i18n/en_US.csv $SRC/i18n/temp.csv
  rm $SRC/i18n/temp.csv
}

function mage_new_path() {
  local ARGS=${@}
  local PATH=""
  local VENDOR=""
  local NAME=""



  read -p "Vendor: " VENDOR
  if [[ -z "$VENDOR" ]]; then echo "The 'Vendor' can not be empty" && exit 1; fi

  read -p "Name: " NAME
  if [[ -z "$NAME" ]]; then echo "The 'Name' can not be empty" && exit 1; fi
}

function mage_new_theme() {
  # Args
  PATH="app/code"

  # Files
  FILE_THEMEXML="<theme\n\txmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n\txsi:noNamespaceSchemaLocation=\"urn:magento:framework:Config/etc/theme.xsd\"\n>\n\t<title>${VENDOR} ${CAMEL_NAME}</title>\n\t<parent>${PARENT}</parent>\n</theme>"
  FILE_REGISTRATION=""
}

function mage_new_mod() {
  TYPE=$1
  SRC=$2
  DIST=$3

  VENDOR="$(echo $VENDOR | tr '[:upper:]' '[:lower:]' | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1' | tr -d '[:blank:]')"
  LOWER_VENDOR="$(tr '[:upper:][:blank:]' '[:lower:]-' <<< ${VENDOR})"
  CAMEL_NAME="$(echo $NAME | tr '[:upper:]' '[:lower:]' | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1' | tr -d '[:blank:]')"
  LOWER_NAME="$(tr '[:upper:][:blank:]' '[:lower:]-' <<< ${NAME})"
  FOLDER_PREFIX="magento2"

  if [[ $TYPE == "theme" ]]; then
    FOLDER_PREFIX="theme"
  fi

  NEW_MOD_PATH=$DIST/$VENDOR/$FOLDER_PREFIX-$LOWER_NAME;

  if [[ -d "$NEW_MOD_PATH" ]]; then
    echo "Theme ($NEW_MOD_PATH) already exists! Try a different name..." && exit 1
  fi

  mkdir -p $NEW_MOD_PATH;

  if [[ $SRC = git@* ]]; then
    cd $NEW_MOD_PATH
    git clone $SRC .
    rm -rf .git

    find ./ -type f -exec perl -pi -e "s/<VENDOR>/${VENDOR}/g" {} +
    find ./ -type f -exec perl -pi -e "s/<VENDOR_PKG>/${LOWER_VENDOR}/g" {} +
    find ./ -type f -exec perl -pi -e "s/<MODULE>/${CAMEL_NAME}/g" {} +
    find ./ -type f -exec perl -pi -e "s/<MODULE_PKG>/${LOWER_NAME}/g" {} +
  else
    PARENT=$(grep -oE "ComponentRegistrar::register\(ComponentRegistrar::THEME, '([^']+)'" "$SRC/registration.php" | awk -F"'" '{print $2}' | sed 's/^frontend\///')

    if [[ -d "$SRC/web/tailwind" ]]; then
      mkdir -p $NEW_MOD_PATH/web/tailwind &&
      rsync -ah $SRC/web/tailwind/ $NEW_MOD_PATH/web/tailwind/ --exclude node_modules
    fi

    touch $NEW_MOD_PATH/registration.php &&
    echo -e "<?php declare(strict_types=1);\n\nuse Magento\Framework\Component\ComponentRegistrar;\n\nComponentRegistrar::register(ComponentRegistrar::THEME, 'frontend/${VENDOR}/${LOWER_NAME}', __DIR__);" >> $NEW_MOD_PATH/registration.php

    if [[ $TYPE == "theme" ]]; then
      NEW_MOD_XML_TEMPLATE="";
      touch $NEW_MOD_PATH/theme.xml &&
      echo -e $NEW_MOD_XML_TEMPLATE >> $NEW_MOD_PATH/theme.xml
    else
      NEW_MOD_XML_TEMPLATE="<?xml version=\"1.0\"?>\n<config\n\txmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n\txsi:noNamespaceSchemaLocation=\"urn:magento:framework:Module/etc/module.xsd\"\n>\n\t<module name=\"${VENDOR}_${CAMEL_NAME}\" setup_version=\"1.0.0\">\n\t\t<sequence>\n\t\t\t<module name=\"Magento_Theme\"/>\n\t\t</sequence>\n\t</module>\n</config>";
      mkdir $NEW_MOD_PATH/etc && touch $NEW_MOD_PATH/etc/module.xml &&
      echo -e $NEW_MOD_XML_TEMPLATE >> $NEW_MOD_PATH/etc/module.xml
    fi
  fi
}
