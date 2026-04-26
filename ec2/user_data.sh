#!/bin/bash
set -euo pipefail

# Install Docker and EFS utilities
dnf update -y
dnf install -y docker amazon-efs-utils

# Start Docker
systemctl enable docker
systemctl start docker

# Mount EFS persistent data volume
mkdir -p /data

# Try IAM-authenticated TLS mount first, fall back to plain NFS
if ! mount -t efs -o tls,iam "${efs_file_system_id}":/ /data 2>/dev/null; then
  mount -t nfs4 \
    -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
    "${efs_file_system_id}.efs.${aws_region}.amazonaws.com":/ /data
fi

# Persist across reboots
echo "${efs_file_system_id}:/ /data efs defaults,_netdev,tls,iam 0 0" >> /etc/fstab

# Setup daily backup to S3 at 2 AM UTC
cat > /usr/local/bin/foundry-backup.sh << 'BACKUP'
#!/bin/bash
set -euo pipefail
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUCKET="phil-foundryvtt"
TMP="/tmp/foundry-backup-$TIMESTAMP.tar.gz"
tar czf "$TMP" -C /data .
aws s3 cp "$TMP" "s3://$BUCKET/snapshots/foundry-efs-backup-$TIMESTAMP.tar.gz" \
  --region "${aws_region}"
rm -f "$TMP"
# Delete backups older than 90 days
aws s3 ls "s3://$BUCKET/snapshots/" --region "${aws_region}" \
  | awk '{print $4}' \
  | while read -r key; do
      ts=$(echo "$key" | grep -oP '\d{8}' | head -1)
      if [ -n "$ts" ] && [ "$(date -d "$ts" +%s 2>/dev/null || echo 0)" -lt "$(date -d '90 days ago' +%s)" ]; then
        aws s3 rm "s3://$BUCKET/snapshots/$key" --region "${aws_region}"
      fi
    done
BACKUP
chmod +x /usr/local/bin/foundry-backup.sh
echo "0 2 * * * root /usr/local/bin/foundry-backup.sh >> /var/log/foundry-backup.log 2>&1" \
  > /etc/cron.d/foundryvtt-backup

# Create the FoundryVTT startup script.
# Terraform bakes in the ARNs, region, image, and hostname at provision time.
# Credentials are always fetched fresh from Secrets Manager at runtime.
cat > /usr/local/bin/start-foundryvtt.sh << 'STARTSCRIPT'
#!/bin/bash
set -euo pipefail

# Remove stale container if present
sudo docker rm -f foundryvtt 2>/dev/null || true

# Fetch credentials fresh from Secrets Manager on every start
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "${foundry_secrets_arn}" \
  --region "${aws_region}" \
  --query SecretString \
  --output text)

FOUNDRY_USERNAME=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['FOUNDRY_USERNAME'])" "$SECRET_JSON")
FOUNDRY_PASSWORD=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['FOUNDRY_PASSWORD'])" "$SECRET_JSON")
FOUNDRY_ADMIN_KEY=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['FOUNDRY_ADMIN_KEY'])" "$SECRET_JSON")
FOUNDRY_LICENSE_KEY=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['FOUNDRY_LICENSE_KEY'])" "$SECRET_JSON")

mkdir -p /data/Config

sudo docker run -d \
  --name foundryvtt \
  --log-driver json-file \
  --log-opt max-size=50m \
  --log-opt max-file=3 \
  -p 80:30000 \
  -v /data:/data \
  -e FOUNDRY_USERNAME="$FOUNDRY_USERNAME" \
  -e FOUNDRY_PASSWORD="$FOUNDRY_PASSWORD" \
  -e FOUNDRY_ADMIN_KEY="$FOUNDRY_ADMIN_KEY" \
  -e FOUNDRY_LICENSE_KEY="$FOUNDRY_LICENSE_KEY" \
  -e OPTIONS_SECRET_ARN="${foundry_options_file_arn}" \
  -e FOUNDRY_HOSTNAME="${subdomain_name}.${domain_name}" \
  -e FOUNDRY_AWS_CONFIG="/data/Config/awsConfig.json" \
  -e AWS_DEFAULT_REGION="${aws_region}" \
  ${foundry_image}
STARTSCRIPT
chmod +x /usr/local/bin/start-foundryvtt.sh

# Systemd service — runs start-foundryvtt.sh on every boot after Docker and network are ready
cat > /etc/systemd/system/foundryvtt.service << 'SERVICE'
[Unit]
Description=FoundryVTT
After=docker.service network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/start-foundryvtt.sh
ExecStop=/usr/bin/docker stop foundryvtt

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable foundryvtt
systemctl start foundryvtt

# Management helper — usage: foundryvtt {start|stop|restart|status|logs}
cat > /usr/local/bin/foundryvtt << 'MGMT'
#!/bin/bash
case "$${1:-}" in
  start)   sudo systemctl start foundryvtt ;;
  stop)    sudo systemctl stop foundryvtt ;;
  restart) sudo docker stop foundryvtt 2>/dev/null; sudo docker start foundryvtt ;;
  status)  sudo docker ps --filter name=foundryvtt --format "table {{.Status}}\t{{.Ports}}" ;;
  logs)    sudo docker logs -f --tail 100 foundryvtt ;;
  mount)
    if mountpoint -q /data; then
      echo "/data is already mounted"
    else
      sudo mount -t efs -o tls,iam ${efs_file_system_id}:/ /data \
        || sudo mount -t nfs4 \
             -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
             ${efs_file_system_id}.efs.${aws_region}.amazonaws.com:/ /data
      echo "/data mounted"
    fi
    ;;
  rotate)
    aws secretsmanager get-secret-value \
      --secret-id "${foundry_options_file_arn}" \
      --region "${aws_region}" \
      --query SecretString \
      --output text | sudo tee /data/Config/s3.json | sudo tee /data/Config/awsConfig.json > /dev/null
    echo "credentials updated — restarting container"
    sudo docker stop foundryvtt && sudo docker start foundryvtt
    ;;
  *)       echo "Usage: foundryvtt {start|stop|restart|status|logs|mount|rotate}" ; exit 1 ;;
esac
MGMT
chmod +x /usr/local/bin/foundryvtt
