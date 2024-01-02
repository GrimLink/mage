#!/bin/bash

files=(
  "_global"
  "version"
  "help"
  "self"-update
  "add"
  "new"
  "set"
  "open"
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
