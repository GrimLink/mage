#!/bin/bash

files=(
  "_global"
  "info"
  "new"
  "open"
  "hyva"
  "sample"
  "_actions"
);

function merge_files() {
  for file in "$@"; do
    cat "src/$file.sh"
    echo
  done
}


# Concatenate the separate files in the desired order
merge_files "${files[@]}" > mage

chmod +x mage
