#!/bin/bash
set -e

echo "Fetching options.json from Secrets Manager..."
mkdir -p /data/Config

if [ -n "$OPTIONS_SECRET_ARN" ]; then
    aws secretsmanager get-secret-value \
        --secret-id "$OPTIONS_SECRET_ARN" \
        --region "${AWS_DEFAULT_REGION:-us-east-1}" \
        --query SecretString \
        --output text > /data/Config/s3.json
    echo "s3.json written successfully"
else
    echo "WARNING: OPTIONS_SECRET_ARN not set, skipping s3.json fetch"
fi

# Remove any stale lock files from previous runs
# EFS/NFS doesn't handle lock files properly, so we clean them up on startup
echo "Checking for stale lock files..."

# Find and display lock files/dirs
echo "Searching for .lock files..."
find /data -name "*.lock" 2>/dev/null | while read -r file; do
    echo "Found lock: $file"
done

# Remove all .lock files or directories (FoundryVTT uses both)
echo "Removing all .lock files..."
find /data -name "*.lock" -exec rm -rf {} + 2>/dev/null || true
rm -rf /data/.lock 2>/dev/null || true

echo "Lock cleanup complete"

# Prevent container cache on EFS to avoid lock file issues
export CONTAINER_CACHE=""

echo "Starting FoundryVTT..."
cd /home/node && exec ./entrypoint.sh "$@"
