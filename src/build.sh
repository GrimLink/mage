#!/usr/bin/env bash

# Build the single mage script from src/mage.sh, by inlining every source line.
# Usage: src/build.sh [OUTPUT], the output defaults to ./mage in the repo root

set -o pipefail

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
root_dir="$(dirname "$src_dir")"
output="${1:-${root_dir}/mage}"

source_pattern='^source "\$\{MAGE_SRC\}/(.+)"$'
version_pattern='^## \[([0-9]+\.[0-9]+\.[0-9]+)\]'

# Echo the first released version in the changelog
function changelog_version() {
  local line

  while IFS= read -r line; do
    if [[ "$line" =~ $version_pattern ]]; then
      echo "${BASH_REMATCH[1]}"
      return 0
    fi
  done < "${root_dir}/CHANGELOG.md"

  return 1
}

# Echo a source file, with its own source lines replaced by their contents
function inline_file() {
  local file="$1"
  local line
  local include

  if [[ ! -f "$file" ]]; then
    echo "Source file not found: ${file}" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ $source_pattern ]]; then
      include="${BASH_REMATCH[1]}"
      echo "# --- ${include}"
      inline_file "${src_dir}/${include}" || return 1
    elif [[ "$line" == 'MAGE_SRC='* ]]; then
      continue
    elif [[ "$line" == 'MAGE_VERSION="dev"' ]]; then
      echo "MAGE_VERSION=\"${version}\""
    else
      printf '%s\n' "$line"
    fi
  done < "$file"
}

if ! version="$(changelog_version)"; then
  echo "No released version found in CHANGELOG.md" >&2
  exit 1
fi

temp="$(mktemp)"
trap 'rm -f "$temp"' EXIT

inline_file "${src_dir}/mage.sh" > "$temp" || exit 1

if ! bash -n "$temp"; then
  echo "The build has syntax errors, ${output} is left untouched" >&2
  exit 1
fi

if command -v shellcheck &> /dev/null; then
  shellcheck -s bash "$temp" || echo "shellcheck reported issues, see above" >&2
fi

mv "$temp" "$output"
chmod 755 "$output"
echo "Built mage ${version} to ${output}"
