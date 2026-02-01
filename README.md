# FoundryVTT Infrastructure as Code

This project deploys a production-ready FoundryVTT game server on AWS using ECS Fargate with Terraform.

## Architecture

The infrastructure includes:

- **ECS Fargate**: Serverless container orchestration running FoundryVTT
- **Application Load Balancer**: HTTP traffic distribution with health checks
- **EFS**: Persistent file storage for game data (worlds, assets, configurations)
- **S3**: Backup storage and asset management
- **Route53**: DNS configuration for custom domain
- **AWS Secrets Manager**: Secure credential storage
- **CloudWatch**: Centralized logging and monitoring
- **VPC**: Default VPC with public subnets for high availability

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0
3. **Docker** (for building custom images)
4. **FoundryVTT License** and credentials
5. **Route53 Hosted Zone** for your domain (optional but recommended)

## Initial Setup

### 1. Configure Terraform Variables

Edit `terraform.tfvars` with your values:

```hcl
# AWS Configuration
aws_region  = "ca-central-1"
environment = "production"

# ECS Configuration
ecs_cluster_arn = "arn:aws:ecs:ca-central-1:YOUR-ACCOUNT-ID:cluster/foundryvtt-cluster"
foundry_image   = "awildphil/foundryvtt:release-13.351.0"
foundry_cpu     = 1024
foundry_memory  = 2048
desired_count   = 1

# Secrets Manager
foundry_secrets_arn      = "arn:aws:secretsmanager:ca-central-1:YOUR-ACCOUNT-ID:secret:foundryvtt-secrets-XXXXX"
foundry_options_file_arn = "arn:aws:secretsmanager:ca-central-1:YOUR-ACCOUNT-ID:secret:options-file-XXXXX"

# EFS Configuration
efs_file_system_id = "fs-XXXXX"

# Route53 Configuration
domain_name    = "your-domain.com"
subdomain_name = "foundryvtt"
```

### 2. Build and Push Docker Image

The Docker image includes AWS CLI for fetching secrets and configurations:

```bash
cd docker
docker build -t awildphil/foundryvtt:latest .
docker push awildphil/foundryvtt:latest
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Usage

### Accessing FoundryVTT

After deployment, access your server at:
```
http://foundryvtt.your-domain.com
```

DNS propagation may take a few minutes.

### Viewing Logs

```bash
# Tail logs in real-time
aws logs tail /ecs/foundryvtt --follow --region ca-central-1

# View recent logs
aws logs tail /ecs/foundryvtt --since 30m --region ca-central-1
```

### Stopping the Service

To stop the service without destroying infrastructure:
```bash
aws ecs update-service \
  --cluster YOUR-CLUSTER-NAME \
  --service foundryvtt-service \
  --desired-count 0 \
  --region ca-central-1
```

### Starting the Service

```bash
aws ecs update-service \
  --cluster YOUR-CLUSTER-NAME \
  --service foundryvtt-service \
  --desired-count 1 \
  --region ca-central-1
```

### Force New Deployment

After updating the Docker image:
```bash
aws ecs update-service \
  --cluster YOUR-CLUSTER-NAME \
  --service foundryvtt-service \
  --force-new-deployment \
  --region ca-central-1
```

### Manual Backup

```bash
# Run the backup script (configured in backup.tf)
aws ecs run-task \
  --cluster YOUR-CLUSTER-NAME \
  --task-definition foundryvtt-backup \
  --launch-type FARGATE \
  --region ca-central-1
```

## Troubleshooting

### Lock File Errors

If you see "directory is already locked by another process" errors, the Docker entrypoint automatically removes stale lock files. If issues persist:

```bash
# Stop the service
aws ecs update-service --cluster YOUR-CLUSTER --service foundryvtt-service --desired-count 0 --region ca-central-1

# Run cleanup task (see cleanup-task.json)
aws ecs run-task \
  --cluster YOUR-CLUSTER \
  --task-definition foundryvtt-cleanup \
  --launch-type FARGATE \
  --region ca-central-1

# Restart service
aws ecs update-service --cluster YOUR-CLUSTER --service foundryvtt-service --desired-count 1 --region ca-central-1
```

### Service Not Starting

Check task status:
```bash
aws ecs describe-services \
  --cluster YOUR-CLUSTER \
  --services foundryvtt-service \
  --region ca-central-1
```

Check task logs:
```bash
aws logs tail /ecs/foundryvtt --follow --region ca-central-1
```

### Health Check Failures

The ALB health check uses `/api/status`. Ensure:
- FoundryVTT is starting successfully (check logs)
- Security groups allow traffic between ALB and ECS tasks
- Container is listening on port 30000

## Cost Optimization

- **Fargate**: ~$30-50/month for 1 vCPU, 2GB RAM running 24/7
- **EFS**: ~$0.30/GB-month
- **ALB**: ~$16/month base + data transfer
- **Route53**: ~$0.50/month per hosted zone

**Total estimated cost**: $50-70/month for 24/7 operation

To reduce costs:
- Stop the service when not gaming
- Use smaller CPU/memory allocation if sufficient
- Consider using Fargate Spot for development

## Security

- Secrets stored in AWS Secrets Manager (never in code)
- EFS encryption at rest enabled
- Security groups restrict traffic to necessary ports
- ECS tasks use IAM roles (no hardcoded credentials)
- Container runs as non-root user
- `terraform.tfvars` and `secrets.json` are gitignored

## Maintenance

### Updating FoundryVTT Version

1. Update `foundry_image` in `terraform.tfvars`
2. Run `terraform apply`
3. Service will automatically deploy new version

### Updating Configuration

1. Update the secret in AWS Secrets Manager:
```bash
aws secretsmanager update-secret \
  --secret-id options-file \
  --secret-string '{ ... }' \
  --region ca-central-1
```

2. Force new deployment to pick up changes:
```bash
aws ecs update-service \
  --cluster YOUR-CLUSTER \
  --service foundryvtt-service \
  --force-new-deployment \
  --region ca-central-1
```

## Destroying Infrastructure

To completely remove all infrastructure:

```bash
# Stop service first
aws ecs update-service --cluster YOUR-CLUSTER --service foundryvtt-service --desired-count 0 --region ca-central-1

# Wait for tasks to stop, then destroy
terraform destroy
```

**Warning**: This will delete all resources but EFS data is persistent. Back up your data first!

## Support

For issues related to:
- **Infrastructure**: Check this repository's issues
- **FoundryVTT**: See [FoundryVTT documentation](https://foundryvtt.com/kb/)
- **AWS**: Refer to AWS service documentation

## License

This infrastructure code is provided as-is. FoundryVTT requires a separate license from Foundry Gaming LLC.

