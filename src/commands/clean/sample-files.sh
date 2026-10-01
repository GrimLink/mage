MAGE_CLEAN_HANDLERS+=("sample-files|Move the *.sample files in the root to dev/sample-files")

function mage_clean_sample_files() {
  mkdir -p dev/sample-files
  find . -maxdepth 1 -type f -name "*.sample" -exec mv {} dev/sample-files/ \;
  mage_check $? "Moved the *.sample files to dev/sample-files"
}
