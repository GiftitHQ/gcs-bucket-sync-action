#!/bin/sh

# Auth
echo "$INPUT_SECRETS" > /secrets.json
gcloud auth activate-service-account --key-file=/secrets.json
rm /secrets.json

# Create temporary directory for syncing
mkdir /tmp/sync-dir

# Include files based on the pattern
echo "Including files: $INPUT_INCLUDE ..."
find /github/workspace/ -regex "$INPUT_INCLUDE" -exec cp --parents \{\} /tmp/sync-dir \;

# Sync files to bucket
echo "Syncing bucket $INPUT_BUCKET ..."
gsutil -m rsync -r -c -d /tmp/sync-dir/ gs://$INPUT_BUCKET/$INPUT_SYNC_DIR
if [ $? -ne 0 ]; then
    echo "Syncing failed"
    exit 1
fi

# Clean up temporary directory
rm -r /tmp/sync-dir

echo "Done."
