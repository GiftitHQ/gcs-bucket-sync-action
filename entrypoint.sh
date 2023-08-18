#!/bin/bash

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
  # Full source path
  src="/github/workspace/$pattern"
  
  # Destination path
  dest="/tmp/sync-dir/$pattern"

  if [ -d "$src" ]; then
    # Source is a directory; create the full path and copy the content
    mkdir -p "$dest"
    cp -r "$src"/* "$dest/"
  else
    # Source is a file; create the parent directory and copy the file
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
  fi

done

# Sync files to bucket
echo "Syncing bucket $INPUT_BUCKET ..."
gsutil rsync -r -c -d /tmp/sync-dir/ gs://$INPUT_BUCKET/$INPUT_SYNC_DIR
if [ $? -ne 0 ]; then
  echo "Syncing failed"
  exit 1
fi

echo "Cache: $INPUT_CACHE"
# Check if no-cache is set to true
if [ "$INPUT_CACHE" = "false" ]; then
  # Set Cache-Control header for all objects in the synced directory
  echo "Setting Cache-Control headers..."
  gsutil -m setmeta -h "Cache-Control:no-cache" gs://$INPUT_BUCKET/$INPUT_SYNC_DIR/**
fi

# Clean up temporary directory
rm -r /tmp/sync-dir

echo "Done."
