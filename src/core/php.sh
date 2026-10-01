# Magento has no command for some of what mage needs, so this boots Magento with php.
# The code gets $objectManager and the functions below, and its arguments as $argv from 1.
MAGE_PHP_BOOTSTRAP='
require "app/bootstrap.php";
$objectManager = \Magento\Framework\App\Bootstrap::create(BP, $_SERVER)->getObjectManager();

function mageAdminUrl($objectManager) {
    $config = $objectManager->get(\Magento\Framework\App\Config\ScopeConfigInterface::class);
    $base = $config->isSetFlag("admin/url/use_custom")
        ? $config->getValue("admin/url/custom")
        : $objectManager->get(\Magento\Store\Model\StoreManagerInterface::class)
            ->getStore(0)->getBaseUrl(\Magento\Framework\UrlInterface::URL_TYPE_WEB, true);
    $frontName = $objectManager->get(\Magento\Backend\App\Area\FrontNameResolver::class)->getFrontName();

    return rtrim($base, "/") . "/" . $frontName . "/";
}
'

function mage_php() {
  local code="$1"
  shift

  $PHP_CLI -r "${MAGE_PHP_BOOTSTRAP}${code}" -- "$@"
}
