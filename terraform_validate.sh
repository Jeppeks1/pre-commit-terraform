#!C:/Program\ Files/Git/bin/bash.exe
set -e

# The terraform validate command has to be run on directories and not files.
# This also requires that the script is run in serialization to avoid race conditions.

declare -a staged_dir
index=0
error=0

# Get the current time in ms
start=$(($(date +%s%N)/1000000))

# Get the modified and staged terraform files that are not to be deleted.
staged=$(git diff --staged --name-only --diff-filter=d)

# Get the directory name of the file and put the value into the staged_dir array
for file in $staged; do
  # Manually check the file extension for appropriate files.
  if [[ $file == *".tf" ]] || [[ $file == *".tfvars" ]] ; then
    staged_dir[index]=$(dirname "$file")
    (("index+=1"))
  fi
done

# Loop over the unique directories that require validation
for distinct_dir in $(echo "${staged_dir[*]}" | tr ' ' '\n' | sort -u); do
  pushd "$distinct_dir" > /dev/null

  # Set a temporary provider in case the current directory is a module without a provider block.
  if [[ ${distinct_dir} == *"modules"* && ! ${distinct_dir} == *"examples"* ]]; then
    echo -e "provider \"azurerm\" {\n  features{}\n}" >| temp-provider.tf
  fi

  # Initialize the directory
  if ! terraform init $validate_path -backend=false; then
    error=1
    echo "==============================================================================="
    echo "Failed terraform init on path: $distinct_dir"
    echo "==============================================================================="
  fi

  # Perform the validation
  if ! terraform validate $validate_path; then
    error=1
    echo "==============================================================================="
    echo "Failed terraform validate on path: $distinct_dir"
    echo "==============================================================================="
  fi

  # Remove the temporary provider block if required.
  if [[ ${distinct_dir} == *"modules"* && ! ${distinct_dir} == *"examples"* ]]; then
    rm temp-provider.tf
  fi

  # Remove the terraform configuration directory that was created after init
  if [[ -d .terraform ]]; then
    rm -r .terraform
  fi
  
  popd > /dev/null
done

# Check if any errors occured
if [[ "${error}" -ne 0 ]]; then
  exit 1
fi

# Output the time it took for the script to run
end=$(($(date +%s%N)/1000000))
echo "The terraform validation script executed in $((end-start)) ms."

