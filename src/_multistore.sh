# ---------------------------------------------------------------------------
# Multistore helpers
# ---------------------------------------------------------------------------

# Append a store entry to .valet-env.php (preserving all existing entries)
function mage_valet_env_add_entry() {
  local domain="$1"
  local code="$2"

  python3 - "$domain" "$code" <<'PYEOF'
import sys, re

domain, code = sys.argv[1], sys.argv[2]
entry = (
    f"\t'{domain}' => [\n"
    f"\t\t'MAGE_RUN_CODE' => '{code}',\n"
    f"\t\t'MAGE_RUN_TYPE' => 'store',\n"
    f"\t],\n"
)

with open('.valet-env.php', 'r') as f:
    content = f.read()

# Skip if domain already present
if f"'{domain}'" in content:
    print(f".valet-env.php already contains '{domain}', skipping.")
    sys.exit(0)

# Insert before the closing ];
content = re.sub(r'^(\];)', entry + r'\1', content, flags=re.MULTILINE)

with open('.valet-env.php', 'w') as f:
    f.write(content)

print(f"Updated .valet-env.php: added '{domain}' → '{code}'")
PYEOF
}

# Add a single store view (interactive)
function mage_add_store() {
  echo ""
  read -e -p "Store code   (e.g. nl_nl): " store_code && echo ""
  read -e -p "Store name   (e.g. Dutch Store): " store_name && echo ""
  read -e -p "Domain name  (e.g. myproject-nl, without .test): " store_domain && echo ""
  read -e -p "Locale code  (e.g. nl_NL, leave empty to skip): " store_locale && echo ""

  if [[ -z "$store_code" || -z "$store_name" || -z "$store_domain" ]]; then
    echo "Error: store code, name and domain are required."
    return 1
  fi

  # Auto-lowercase the store code
  store_code=$(echo "$store_code" | tr '[:upper:]' '[:lower:]')

  if [[ ! "$store_code" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "Error: store code must be letters, digits and underscores, starting with a letter (got: ${store_code})."
    return 1
  fi

  echo "Creating store group and store view in Magento..."
  local php_args="--code=${store_code} --name=${store_name}"
  if [[ -n "$store_locale" ]]; then
    php_args="${php_args} --locale=${store_locale}"
  fi

  if ! $PHP_CLI dev/tools/create-store.php $php_args; then
    echo "Error: failed to create store entities."
    return 1
  fi

  echo "Setting base URLs..."
  $MAGENTO_CLI config:set --scope=stores --scope-code="$store_code" web/unsecure/base_url "https://${store_domain}.test/"
  $MAGENTO_CLI config:set --scope=stores --scope-code="$store_code" web/secure/base_url   "https://${store_domain}.test/"
  $MAGENTO_CLI config:set --scope=stores --scope-code="$store_code" web/secure/use_in_frontend 1

  echo "Flushing cache..."
  $MAGENTO_CLI cache:flush

  echo "Updating .valet-env.php..."
  mage_valet_env_add_entry "$store_domain" "$store_code"

  echo ""
  echo "Store '${store_code}' created."

  if [[ $VALET == 1 ]]; then
    echo ""
    echo "Linking and securing Valet domain..."
    valet link "${store_domain}"
    valet secure "${store_domain}"
  fi
  echo ""
}

# Add all stores defined in dev/tools/stores.json (batch, non-interactive)
# Schema: { "stores": [ { "code": "nl_nl", "name": "Dutch", "suffix": "nl", "locale": "nl_NL" } ] }
# The domain is computed as <project-name>-<suffix> so stores.json stays project-agnostic.
function mage_add_stores_from_file() {
  local stores_file="${1:-}"

  # Resolve file: dev/tools/ → project root → mage bin dir
  if [[ -z "$stores_file" ]]; then
    if [[ -f "dev/tools/stores.json" ]]; then
      stores_file="dev/tools/stores.json"
    elif [[ -f "stores.json" ]]; then
      stores_file="stores.json"
    elif [[ -f "$(dirname "$0")/stores.json" ]]; then
      stores_file="$(dirname "$0")/stores.json"
    fi
  fi

  if [[ -z "$stores_file" || ! -f "$stores_file" ]]; then
    echo "No stores.json found (checked dev/tools/, project root, and mage bin dir)."
    return 0
  fi

  echo "Reading stores from ${stores_file}..."

  local project_name
  project_name=$(basename "$(pwd)")

  # Parse JSON with Python 3 — output one line per store: code|name|suffix|locale
  local stores_data
  stores_data=$(python3 - "$stores_file" <<'PYEOF'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
stores = data.get("stores", [])
if not stores:
    print("__empty__")
    sys.exit(0)
for s in stores:
    code   = s.get("code", "")
    name   = s.get("name", "")
    suffix = s.get("suffix", "")
    locale = s.get("locale", "")
    if not code or not name or not suffix:
        print(f"__skip__: missing field in entry: {s}", file=__import__('sys').stderr)
        continue
    print(f"{code}|{name}|{suffix}|{locale}")
PYEOF
)

  if [[ "$stores_data" == "__empty__" ]]; then
    echo "No stores defined in ${stores_file}."
    return 0
  fi

  local created=0
  local new_domains=()
  while IFS='|' read -r s_code s_name s_suffix s_locale; do
    [[ -z "$s_code" ]] && continue

    local s_domain="${project_name}-${s_suffix}"

    echo ""
    echo "→ Creating store: ${s_code} (${s_name}) at ${s_domain}.test"

    local php_args="--code=${s_code} --name=${s_name}"
    if [[ -n "$s_locale" ]]; then
      php_args="${php_args} --locale=${s_locale}"
    fi

    if ! $PHP_CLI dev/tools/create-store.php $php_args; then
      echo "  Skipping ${s_code} due to error."
      continue
    fi

    $MAGENTO_CLI config:set --scope=stores --scope-code="$s_code" web/unsecure/base_url "https://${s_domain}.test/"
    $MAGENTO_CLI config:set --scope=stores --scope-code="$s_code" web/secure/base_url   "https://${s_domain}.test/"
    $MAGENTO_CLI config:set --scope=stores --scope-code="$s_code" web/secure/use_in_frontend 1

    mage_valet_env_add_entry "$s_domain" "$s_code"

    new_domains+=("$s_domain")
    (( created++ ))
  done <<< "$stores_data"

  if [[ "$created" -gt 0 ]]; then
    echo ""
    echo "Flushing cache..."
    $MAGENTO_CLI cache:flush

    if [[ $VALET == 1 && ${#new_domains[@]} -gt 0 ]]; then
      echo ""
      echo "Linking Valet domains..."
      for d in "${new_domains[@]}"; do
        valet link "$d"
      done
      echo ""
      echo "Securing Valet domains..."
      for d in "${new_domains[@]}"; do
        valet secure "$d"
      done
    fi

    echo ""
    echo "${created} store(s) created."
  fi
}
