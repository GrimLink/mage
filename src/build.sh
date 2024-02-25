#!/bin/bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
sorted_files=("_global")
files=("${script_dir}"/_*)

for file in "${files[@]}"; do
  [[ "${file}" == "${script_dir}"/_mage ]] || [[ "${file}" == "${script_dir}"/_global ]] || sorted_files+=("${file#${script_dir}/}")
done

# Add _mage to the end
sorted_files+=("_mage")

function merge_files() {
  echo -e "#!/bin/bash\n"
  echo "# Mage is a collection of easy commands and aliases for bin/magento"
  echo -e "# For those who hate typing long shell commands\n"

  for file in "$@"; do
    cat "${script_dir}/${file}"
    echo
  done
}

merge_files "${sorted_files[@]}" > ../mage
chmod +x ../mage
