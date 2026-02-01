#!/bin/bash
set -e

# Configuration
S3_BUCKET="${S3_BUCKET:-phil-foundryvtt}"
S3_PREFIX="${S3_PREFIX:-snapshots}"
BACKUP_SOURCE="${BACKUP_SOURCE:-/data}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="foundry-efs-backup-${TIMESTAMP}.tar.gz"
TEMP_DIR="/tmp/backup"

echo "Starting FoundryVTT EFS backup at $(date)"
echo "Source: ${BACKUP_SOURCE}"
echo "Destination: s3://${S3_BUCKET}/${S3_PREFIX}/${BACKUP_NAME}"

# Create temporary directory
mkdir -p "${TEMP_DIR}"

# Create compressed archive
echo "Creating compressed archive..."
tar -czf "${TEMP_DIR}/${BACKUP_NAME}" -C "${BACKUP_SOURCE}" .

# Get file size
BACKUP_SIZE=$(du -h "${TEMP_DIR}/${BACKUP_NAME}" | cut -f1)
echo "Backup size: ${BACKUP_SIZE}"

# Upload to S3
echo "Uploading to S3..."
aws s3 cp "${TEMP_DIR}/${BACKUP_NAME}" "s3://${S3_BUCKET}/${S3_PREFIX}/${BACKUP_NAME}"

# Clean up
rm -f "${TEMP_DIR}/${BACKUP_NAME}"

echo "Backup completed successfully at $(date)"
echo "Backup location: s3://${S3_BUCKET}/${S3_PREFIX}/${BACKUP_NAME}"

# Optional: Delete backups older than 30 days
echo "Cleaning up old backups (>30 days)..."
aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" | \
  awk '{print $4}' | \
  grep "^foundry-efs-backup-" | \
  while read -r file; do
    FILE_DATE=$(echo "$file" | sed 's/foundry-efs-backup-\([0-9]*\)-.*/\1/')
    FILE_AGE=$(( ($(date +%s) - $(date -d "${FILE_DATE:0:4}-${FILE_DATE:4:2}-${FILE_DATE:6:2}" +%s)) / 86400 ))
    if [ "$FILE_AGE" -gt 30 ]; then
      echo "Deleting old backup: $file (${FILE_AGE} days old)"
      aws s3 rm "s3://${S3_BUCKET}/${S3_PREFIX}/$file"
    fi
  done

echo "Backup process finished"
