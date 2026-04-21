# FoundryVTT Infrastructure as Code

Deploys FoundryVTT on an EC2 instance (`t3.small`) with EFS persistent storage. Route53 points directly at an Elastic IP — no load balancer.

**Estimated cost: ~$5–6/month** (instance runs ~9 hrs/day via scheduler).

The archived ECS deployment is in [archive/ecs/](archive/ecs/).

---

## Architecture

```
Route53 A record (foundryvtt.edge-of-the-universe.ca)
    → Elastic IP
    → EC2 t3.small (Amazon Linux 2023)
        ├─ Docker: FoundryVTT (-p 80:30000)
        ├─ EFS /data  (worlds, assets, config)
        ├─ IAM profile → Secrets Manager + S3
        └─ systemd: starts container on every boot
```

Scheduling: EventBridge Scheduler stops the instance at 07:00 UTC and starts it at 22:00 UTC daily (~9 hrs/day).

Backups: cron job at 02:00 UTC tars `/data` → `s3://phil-foundryvtt/snapshots/`, retaining 90 days.

---

## Prerequisites

These resources must exist before deploying. They are **not** created by this Terraform.

| Resource | ID / ARN |
|---|---|
| EFS file system | `fs-068eb40423baef0e9` |
| Secrets Manager — FoundryVTT credentials | `arn:aws:secretsmanager:ca-central-1:461706357402:secret:foundryvtt-secrets-PE2VMK` |
| Secrets Manager — options file | `arn:aws:secretsmanager:ca-central-1:461706357402:secret:options-file-jirLDj` |
| S3 bucket | `phil-foundryvtt` |
| Route53 hosted zone | `edge-of-the-universe.ca` |

The `foundryvtt-secrets` secret must be a JSON object with these keys:
```json
{
  "FOUNDRY_USERNAME": "...",
  "FOUNDRY_PASSWORD": "...",
  "FOUNDRY_ADMIN_KEY": "...",
  "FOUNDRY_LICENSE_KEY": "..."
}
```

---

## Deployment

### 1. Deploy infrastructure

```bash
cd ec2/
terraform init
terraform plan
terraform apply
```

### 2. Verify EFS is mounted

> **Known timing issue**: Terraform creates the EC2 instance and the EFS security group rule in the same apply. The instance may boot and run `user_data.sh` before the NFS rule propagates, causing the EFS mount to fail silently.

After `apply` completes, connect via SSM and check:

```bash
aws ssm start-session \
  --target $(terraform output -raw instance_id) \
  --region ca-central-1
```

Then on the instance:

```bash
mount | grep /data
```

**If EFS is not mounted**, mount it manually and restart the service:

```bash
sudo mount -t efs -o tls,iam fs-068eb40423baef0e9:/ /data

# If the above fails, fall back to plain NFS:
sudo mount -t nfs4 \
  -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  fs-068eb40423baef0e9.efs.ca-central-1.amazonaws.com:/ /data

sudo systemctl restart foundryvtt
```

The EFS security group (`sg-0b4306f19233f1240`, the default VPC SG) is managed by [ec2/efs.tf](ec2/efs.tf) which adds the NFS ingress rule automatically. On any subsequent `terraform apply` the rule will be present before the instance is replaced.

### 3. Verify FoundryVTT is running

```bash
sudo systemctl status foundryvtt
sudo docker ps
sudo docker logs foundryvtt --tail 50
```

Access at `http://foundryvtt.edge-of-the-universe.ca` — first visit redirects to `/license` for signing the software license.

---

## Operations

### Connect to the instance (no SSH required)

```bash
aws ssm start-session \
  --target $(terraform -chdir=ec2 output -raw instance_id) \
  --region ca-central-1
```

### View logs

```bash
sudo docker logs foundryvtt --follow
```

### Restart FoundryVTT

```bash
sudo systemctl restart foundryvtt
```

### Manual start/stop of EC2

```bash
# Stop
aws ec2 stop-instances --instance-ids $(terraform -chdir=ec2 output -raw instance_id) --region ca-central-1

# Start
aws ec2 start-instances --instance-ids $(terraform -chdir=ec2 output -raw instance_id) --region ca-central-1
```

### Manual backup

```bash
sudo /usr/local/bin/foundry-backup.sh
```

### Update FoundryVTT version

1. Build and push a new Docker image:
   ```bash
   cd docker/
   make push
   ```
2. Update `foundry_image` in [ec2/terraform.tfvars](ec2/terraform.tfvars)
3. `terraform apply` — replaces the instance, which re-runs `user_data.sh`

---

## Troubleshooting

### EFS not mounted after deploy

See step 2 above. Root cause: NFS security group rule and instance creation race. Fixed on any subsequent instance replacement.

### Lock file error on startup

FoundryVTT will fail with "directory is already locked" if a previous instance left a lock file on EFS. This typically happens when the old ECS service was still running against the same EFS.

```bash
# Confirm EFS is mounted first, then:
sudo find /data -name "*lock*" 2>/dev/null
sudo rm -rf /data/.lock
sudo systemctl restart foundryvtt
```

### Container starts but no credentials

The systemd service fetches credentials from Secrets Manager on every start. If it fails:

```bash
# Check the service log
sudo journalctl -u foundryvtt -n 50

# Manually test credential fetch
aws secretsmanager get-secret-value \
  --secret-id arn:aws:secretsmanager:ca-central-1:461706357402:secret:foundryvtt-secrets-PE2VMK \
  --region ca-central-1 \
  --query SecretString \
  --output text
```

### DNS not resolving

The Route53 TTL is 60 seconds. If your local resolver has a stale entry:

```bash
# macOS
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Verify directly against Route53
nslookup foundryvtt.edge-of-the-universe.ca 8.8.8.8
```

---

## Docker image

The custom image adds AWS CLI to `felddy/foundryvtt` so the entrypoint can fetch the options file from Secrets Manager.

```bash
cd docker/
make push   # builds and pushes awildphil/foundryvtt:release-13.351.0 + :latest
```

---

## Destroying infrastructure

```bash
cd ec2/
terraform destroy
```

This does **not** delete the EFS, Secrets Manager secrets, S3 bucket, or Route53 hosted zone — those are pre-existing and managed outside this Terraform.
