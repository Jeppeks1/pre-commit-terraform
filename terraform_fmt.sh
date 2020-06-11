#!C:/Program\ Files/Git/bin/bash.exe
set -e

# The terraform fmt command can be run on individual files and the
# pre-commit yaml configuration therefore sets require_serial to false.

# Get the staged terraform files that are not to be deleted.
staged=$(git diff --staged --name-only --diff-filter=d)

for file in $staged; do
  # Check if the staged file is present in the input array, and therefore
  # contains the appropriate extension defined in pre-commit-config.yaml.
  for input in "$@"; do
    if [[ "$file" == "$input" ]]; then
      # Format the .tf or .tfvars file
      terraform fmt $file
    fi
  done
done