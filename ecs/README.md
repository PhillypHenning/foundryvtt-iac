# FoundryVTT ECS Infrastructure

This directory contains the Terraform configuration for deploying FoundryVTT on AWS ECS with Fargate.

## Architecture

The infrastructure includes:

- **ECS Fargate**: Serverless container orchestration running the FoundryVTT Docker container
- **Application Load Balancer**: Distributes traffic with HTTPS termination
- **EFS**: Persistent file storage for game data
- **S3**: Asset storage and backups
- **VPC**: Isolated network with public and private subnets across multiple availability zones
- **Route53**: DNS configuration
- **ACM**: SSL/TLS certificate management
- **CloudWatch**: Logging and monitoring

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0
3. An existing ECS cluster (ARN provided in terraform.tfvars)
4. A Route53 hosted zone for your domain
5. FoundryVTT license credentials

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   - ECS cluster ARN
   - Domain name and Route53 zone ID
   - FoundryVTT credentials
   - Resource sizing (CPU, memory)

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Deployment

After successful deployment:

1. DNS propagation may take a few minutes
2. Certificate validation occurs automatically via Route53
3. The ECS service will start the FoundryVTT container
4. Access your server at `https://your-domain.com`

## Management

### View logs:
```bash
aws logs tail /ecs/foundryvtt --follow
```

### Access container shell:
```bash
aws ecs execute-command \
  --cluster alert-deer-g96srp \
  --task <task-id> \
  --container foundryvtt \
  --interactive \
  --command "/bin/bash"
```

### Update task:
```bash
terraform apply
```

## Cost Optimization

- Fargate pricing based on vCPU and memory
- NAT Gateways incur hourly charges
- EFS charges based on storage used
- Consider stopping the service when not in use: `terraform destroy`

## Security

- All secrets stored in terraform.tfvars (gitignored)
- Containers run in private subnets
- Only ALB is publicly accessible
- HTTPS enforced with TLS 1.3
- EFS and S3 encrypted at rest

## Troubleshooting

Check ECS task status:
```bash
aws ecs describe-services \
  --cluster alert-deer-g96srp \
  --services foundryvtt-service
```

View task logs in CloudWatch or:
```bash
aws logs tail /ecs/foundryvtt --follow
```
