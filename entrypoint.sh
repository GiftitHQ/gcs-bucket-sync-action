#!/bin/sh

# Auth
echo "$INPUT_SECRETS" > /secrets.json
gcloud auth activate-service-account --key-file=/secrets.json
rm /secrets.json

# Create temp dir
rm -rf /tmp/sync-dir/
mkdir -p /tmp/sync-dir

# Include files based on the pattern
include_files="$INPUT_INCLUDE"

# Split patterns
patterns=(${include_files//|/ })

# Copy files and create directories
for pattern in "${patterns[@]}"; do
  # Get directory from pattern
  dir=$(dirname "$pattern")

  # Create dir in tmp folder
  mkdir -p "/tmp/sync-dir/$dir"

  # Copy files
  find /github/workspace/ -regex "$pattern" -exec cp --parents \{\} "/tmp/sync-dir/$dir/" \;

done

# Sync files to bucket
echo "Syncing bucket $INPUT_BUCKET ..."
gsutil rsync -r -c -d /tmp/sync-dir/ gs://$INPUT_BUCKET/$INPUT_SYNC_DIR
if [ $? -ne 0 ]; then
  echo "Syncing failed"
  exit 1
fi

# Clean up temporary directory
rm -r /tmp/sync-dir

echo "Done."
