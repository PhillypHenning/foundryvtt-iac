#!/bin/bash
set -e

echo "Fetching options.json from Secrets Manager..."
mkdir -p /data/Config

if [ -n "$OPTIONS_SECRET_ARN" ]; then
    aws secretsmanager get-secret-value \
        --secret-id "$OPTIONS_SECRET_ARN" \
        --region "${AWS_DEFAULT_REGION:-us-east-1}" \
        --query SecretString \
        --output text > /data/Config/options.json
    echo "options.json written successfully"

    aws secretsmanager get-secret-value \
        --secret-id "$S3_SECRET_ARN" \
        --region "${AWS_DEFAULT_REGION:-us-east-1}" \
        --query SecretString \
        --output text > /data/Config/s3.json
    echo "s3.json written successfully"
else
    echo "WARNING: OPTIONS_SECRET_ARN not set, skipping options.json fetch"
fi

# Remove any stale lock files from previous runs
# EFS/NFS doesn't handle lock files properly, so we clean them up on startup
echo "Checking for stale lock files..."
if [ -f /data/.lock ]; then
    echo "Removing stale lock file: /data/.lock"
    rm -f /data/.lock
fi
if [ -f /data/Config/options.json.lock ]; then
    echo "Removing stale lock file: /data/Config/options.json.lock"
    rm -f /data/Config/options.json.lock
fi

echo "Starting FoundryVTT..."
cd /home/node && exec ./entrypoint.sh "$@"
