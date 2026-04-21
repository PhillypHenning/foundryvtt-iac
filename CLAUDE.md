# FoundryVTT Infrastructure – CLAUDE.md

## Project Overview
Terraform-managed AWS infrastructure for a self-hosted FoundryVTT game server.
Region: `ca-central-1` | Account: `461706357402`

---

## Architecture

```
Internet → Route53 (foundryvtt.edge-of-the-universe.ca)
         → ALB (port 80, HTTP only)
         → ECS Fargate Task (port 30000)
              ├── EFS mount (/data) — persistent game data
              └── Secrets Manager — credentials/license

EventBridge (daily 2 AM UTC) → ECS Fargate backup task
                                    └── S3 (phil-foundryvtt/snapshots/, 90-day retention)
```

## Key Resources

| Resource | Config | Est. Monthly Cost |
|---|---|---|
| ECS Fargate (main) | 1 vCPU / 2 GB RAM, 24/7 | ~$36 on-demand / ~$11 Spot |
| ALB | Application LB, HTTP:80 only | ~$16 |
| EFS | `fs-068eb40423baef0e9` (existing) | ~$0.30/GB |
| S3 | `phil-foundryvtt`, 90-day backup retention | minimal |
| Route53 | `edge-of-the-universe.ca` hosted zone | ~$0.50 |
| Secrets Manager | 2 secrets | ~$0.80 |
| ECS Backup task | 0.25 vCPU / 512 MB, runs ~2 min/day | ~$0.05 |
| CloudWatch Logs | 7-day retention | minimal |
| **Public IPv4 (VPC charge)** | ALB uses 2 IPs, ECS task uses 1 IP | **~$11/month** |

**Public IPv4 note**: AWS has charged $0.005/hour per public IPv4 since Feb 2024.
The ALB spans 2 AZs = 2 IPs + 1 ECS task IP = 3 IPs × $3.65 = **~$10.95/month** — this is the "$11.74 VPC charge."

## Cost Investigation: $30 → $170

Expected costs from Terraform-managed resources: **~$65/month**
Actual bill: **~$170/month** — gap of **~$105**

**Most likely cause: Orphaned EC2 resources from the EC2→ECS migration.**

Check the AWS console for these in `ca-central-1`:
- EC2 instances (Instances → filter by running)
- EBS volumes (Elastic Block Store → Volumes → filter by "available" or "in-use")
- Elastic IPs (EC2 → Elastic IPs — $3.65/month each if unattached)
- NAT Gateways (VPC → NAT Gateways)
- Old security groups / load balancers

The git history shows `migration_to_ecs` was done recently. Any EC2 instance left running
would add $15–100/month depending on instance type.

## Cost Optimization – Implemented

### Fargate Spot (controlled by `use_spot` variable)
- `use_spot = true` (default): Uses FARGATE_SPOT capacity provider — saves ~70% on compute
  - Savings: $36/month → ~$11/month = **~$25/month saved**
  - Risk: AWS can interrupt Spot tasks (rare but possible mid-session)
  - Data is safe — EFS persists across restarts
- `use_spot = false`: Uses standard FARGATE — fully reliable, higher cost

### Scheduled Stop/Start (not yet implemented)
If you game on a fixed schedule (e.g., weekends only), add EventBridge rules
to set `desired_count` to 0/1. Example: gaming 16 hours/week:
- 64 hours/month instead of 730 = 91% compute reduction
- Spot cost: $11 × 9% = ~$1/month — saves ~$35/month
- See "Operations" section for manual stop/start commands

## Terraform Variables

| Variable | Default | Description |
|---|---|---|
| `foundry_cpu` | 1024 | vCPU units (256, 512, 1024, 2048) |
| `foundry_memory` | 2048 | RAM in MB |
| `desired_count` | 1 | Running tasks (set to 0 to stop) |
| `use_spot` | true | Fargate Spot pricing (cheaper, interruptible) |
| `foundry_image` | `awildphil/foundryvtt:release-13.351.0` | Docker image tag |

## Common Operations

```bash
# Stop the server (saves compute costs)
aws ecs update-service \
  --cluster alert-deer-g96srp \
  --service foundryvtt-service \
  --desired-count 0 \
  --region ca-central-1

# Start the server
aws ecs update-service \
  --cluster alert-deer-g96srp \
  --service foundryvtt-service \
  --desired-count 1 \
  --region ca-central-1

# Force redeploy (pull latest image)
aws ecs update-service \
  --cluster alert-deer-g96srp \
  --service foundryvtt-service \
  --force-new-deployment \
  --region ca-central-1

# Check running tasks
aws ecs list-tasks \
  --cluster alert-deer-g96srp \
  --service-name foundryvtt-service \
  --region ca-central-1
```

## Terraform Operations

```bash
# Deploy changes
terraform init
terraform plan
terraform apply

# Switch between Spot and on-demand
# Edit terraform.tfvars: use_spot = true/false
terraform apply

# Destroy all (careful!)
terraform destroy
```

## Docker Image

Custom image built from `docker/Dockerfile` based on `felddy/foundryvtt`.
Published to Docker Hub as `awildphil/foundryvtt`.

```bash
make build   # build image
make push    # build + push to Docker Hub
make all     # same as push
```

## State Backend
Remote S3 backend: `ph-terraform-state-bucket`

## Notes
- EFS (`fs-068eb40423baef0e9`) is pre-existing — not created by this Terraform
- ECS cluster (`alert-deer-g96srp`) is pre-existing — not created by this Terraform
- No HTTPS configured — only HTTP on port 80 (consider adding ACM cert + HTTPS listener)
- `enable_execute_command = true` on ECS service (allows `aws ecs execute-command` for debugging)
