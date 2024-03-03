#!/bin/bash

script_dir="$(cd "$( dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Initialize sorted_files with _global
sorted_files=("_global.sh")

# Find remaining files and add to sorted_files
files=("${script_dir}"/_*.sh)
for file in "${files[@]}"; do
  [[ "${file}" == "${script_dir}"/_mage.sh ]] || [[ "${file}" == "${script_dir}"/_global.sh ]] || sorted_files+=("${file#${script_dir}/}")
done

# Add _mage to the end
sorted_files+=("_mage.sh")

function merge_files() {
  echo -e "#!/bin/bash\n"
  echo "# Mage is a collection of easy commands and aliases for bin/magento"
  echo -e "# For those who hate typing long shell commands\n"

  for file in "$@"; do
    cat "${script_dir}/${file}"
    echo
  done
}

merge_files "${sorted_files[@]}" > "${script_dir}/../mage"
chmod +x "${script_dir}/../mage"
