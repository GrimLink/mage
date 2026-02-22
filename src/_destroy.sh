# Fully remove a Magento project: folder, database, and all Valet links/certs.
# Run from the PARENT directory of the project, e.g.:
#   cd ~/Developer/magento && mage destroy my-project
function mage_destroy_project() {
  local name="$1"

  if [[ -z "$name" ]]; then
    echo "Usage: mage destroy <PROJECT-NAME>"
    return 1
  fi

  if [[ ! -d "$name" ]]; then
    echo "Error: Directory '${name}' not found in the current folder ($(pwd))."
    echo "Run this command from the parent directory of the project."
    return 1
  fi

  # Gather Valet domains by reading .valet-env.php — only top-level array keys
  # (the ones with array values) are domain names; string-value keys are skipped.
  local valet_env="${name}/.valet-env.php"
  local domains=()
  if [[ -f "$valet_env" ]]; then
    while IFS= read -r _d; do
      [[ -n "$_d" ]] && domains+=("$_d")
    done < <(python3 -c "
import re, sys
content = open(sys.argv[1]).read()
for k in re.findall(r\"'([^']+)'\\s*=>\\s*\\[\", content):
    print(k)
" "$valet_env")
  fi

  echo ""
  echo -e "${RED}WARNING: This will permanently destroy:${RESET}"
  echo "  • Project folder : $(pwd)/${name}"
  echo "  • Database       : ${name}"
  if [[ ${#domains[@]} -gt 0 ]]; then
    echo "  • Valet domains  : ${domains[*]}"
  fi
  echo ""
  read -p "Type the project name to confirm: " _confirm && echo ""

  if [[ "$_confirm" != "$name" ]]; then
    echo -e "Aborted — '${_confirm}' does not match '${name}'."
    return 1
  fi

  # Valet cleanup — delete cert files, nginx configs, and site symlinks directly
  # so we can do a single valet restart instead of one nginx restart per domain.
  if [[ $VALET == 1 && ${#domains[@]} -gt 0 ]]; then
    local _valet_cfg="$HOME/.config/valet"
    echo "Removing Valet certificates, nginx configs and site links..."
    for d in "${domains[@]}"; do
      rm -f "${_valet_cfg}/Certificates/${d}.test.crt" \
            "${_valet_cfg}/Certificates/${d}.test.csr" \
            "${_valet_cfg}/Certificates/${d}.test.key" \
            "${_valet_cfg}/Certificates/${d}.test.conf"
      rm -f "${_valet_cfg}/Nginx/${d}.test"
      rm -f "${_valet_cfg}/Sites/${d}"
      sudo security delete-certificate -c "${d}.test" \
        /Library/Keychains/System.keychain 2>/dev/null || true
    done
    echo "Restarting nginx once..."
    valet restart
  fi

  # Drop database
  echo "Dropping database '${name}'..."
  if command -v mysql &>/dev/null; then
    mysql -uroot -proot -e "DROP DATABASE IF EXISTS \`${name}\`;" 2>/dev/null \
      || echo "  Warning: could not drop database (check credentials)."
  else
    echo "  Warning: mysql not found — skipping database removal."
  fi

  # Remove project folder
  echo "Removing project folder '${name}'..."
  rm -rf "${name}"

  echo ""
  echo -e "${GREEN}✓ Project '${name}' has been fully removed.${RESET}"
}
