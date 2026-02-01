# FoundryVTT Infrastructure as Code - Copilot Instructions

## Project Overview
This is a Terraform Infrastructure as Code (IaC) project that deploys a FoundryVTT game server on AWS. The infrastructure includes:
- EC2 instance running FoundryVTT in Docker
- External EFS mount for persistent game data storage at `/mnt/efs`
- S3 bucket for configuration files, assets, and backups
- Route53 DNS configuration
- IAM roles and policies for secure access
- Elastic IP for static addressing
- Security groups for network access control

## Architecture Highlights

### Core Components
- **EC2 Instance**: Runs Amazon Linux 2 with Docker Compose hosting FoundryVTT container
- **EFS Mount**: External EFS filesystem mounted at `/mnt/efs`, symlinked to `/home/ec2-user/foundry/data` for persistent game data
- **S3 Storage**: 
  - Configuration files (options.json, secrets.json)
  - Game assets accessible by FoundryVTT
  - Automated weekly backups via cron job
- **Domain**: Uses Route53 for DNS management with subdomain configuration
- **Elastic IP**: Static IP address for consistent access

### Important Notes
- The EFS filesystem is **NOT** managed by Terraform - it's referenced via `var.efs_safehouse`
- The EFS should be preserved and backed up before any infrastructure changes
- Backups run weekly (Sunday 3 AM) via cron job on the EC2 instance
- Docker Compose file is generated dynamically in user_data script

## Development Guidelines

### Always Follow These Rules
1. **EFS Protection**: Never destroy or recreate the EFS - game data lives there
2. **State Management**: Backend state is stored in S3 bucket `ph-terraform-state-bucket`
3. **Region Consistency**: Primary region is `ca-central-1`
4. **Security**: Admin IPs are controlled via `var.admin_ips` - never expose SSH globally
5. **Secrets**: Never commit `terraform.tfvars`, `secrets.json`, or `options.json` (use .gitignore)

### Code Style
- Use clear resource naming with prefixes like `foundry_*`
- Always include `depends_on` when resources have implicit dependencies
- Add descriptive comments for complex configurations
- Keep user_data scripts readable with clear sections
- Use variables for all configurable values

### Testing Approach
1. Always run `terraform plan` before `terraform apply`
2. Validate changes don't affect the EFS mount
3. Test backups after infrastructure changes
4. Verify security group rules maintain proper access control
5. Check that domain DNS resolves correctly after Route53 changes

### Common Tasks

#### Adding New Variables
- Add to `variables.tf` with clear descriptions
- Update `terraform.tfvars.example` with example values
- Document in README.md if user-facing

#### Modifying User Data
- Changes require EC2 instance recreation
- Always test Docker Compose syntax before applying
- Ensure EFS mount commands are preserved
- Verify S3 file retrieval works with updated IAM permissions

#### S3 Bucket Access
- Bot user has read-only access to `GameData/*`
- EC2 instance role has read access to config files
- EC2 instance role has write access for backups to `snapshots/`

#### Backup Configuration
- Backup script in `ec2.tf` as `data.template_file.backup_script`
- Deployed via `null_resource.cron_backup`
- Runs weekly, zips data directory, uploads to S3
- Force re-deployment by updating the `force` trigger value

## File Structure

### Terraform Files
- `provider.tf` - AWS provider and S3 backend configuration
- `variables.tf` - All input variables
- `ec2.tf` - EC2 instance, EIP, and backup configuration
- `networking.tf` - Security groups and network rules
- `iam.tf` - IAM roles, policies, and user access
- `s3_acl.tf` - S3 bucket policies and CORS configuration
- `route53.tf` - DNS records
- `foundry-options.tf` - Generates FoundryVTT options.json config
- `outputs.tf` - Output values (IPs, access keys)
- `lb.tf` - Load balancer config (currently commented out)

### Configuration Files
- `terraform.tfvars` - Actual values (git-ignored)
- `terraform.tfvars.example` - Template for users
- `options.json.tmpl` - Template for FoundryVTT AWS S3 configuration
- `secrets.json` - FoundryVTT license key (git-ignored)

## Current Infrastructure State

### Managed Resources
```
data.aws_route53_zone.selected
data.aws_security_group.selected
data.template_file.backup_script
aws_eip.foundry_eip
aws_iam_access_key.foundry_botuser_access_key
aws_iam_instance_profile.instance_profile
aws_iam_policy.foundry_botuser_s3_policy
aws_iam_policy.s3_access_policy
aws_iam_role.instance_role
aws_iam_role_policy_attachment.attach_s3_access
aws_iam_user.foundry_botuser
aws_iam_user_policy_attachment.foundry_botuser_attach_s3_policy
aws_instance.foundry_instance
aws_route53_record.foundryvtt_record
aws_s3_bucket_cors_configuration.foundry-s3bucket
aws_s3_bucket_policy.foundry-botuser-read-access
aws_s3_object.options_json
aws_security_group.allow_specific_ips
local_sensitive_file.options_json
null_resource.cron_backup
```

### External Dependencies (Not in State)
- EFS filesystem (referenced via `var.efs_safehouse`)
- S3 bucket `phil-foundryvtt` (assumed to exist)
- Route53 hosted zone (data source)
- Default VPC security group (data source)

## Troubleshooting

### Common Issues
1. **EFS Mount Fails**: Check security group allows NFS (port 2049) from VPC CIDR
2. **Docker Won't Start**: Verify user_data script executed successfully, check `/var/log/cloud-init-output.log`
3. **S3 Access Denied**: Verify IAM instance profile is attached and policies are correct
4. **Backup Fails**: Check EC2 instance role has PutObject permission for snapshots directory

### Debugging Commands
```bash
# SSH into instance
ssh -i ./foundryvtt-keypair.pem ubuntu@<instance-ip>

# Check Docker status
sudo docker ps

# View logs
sudo docker-compose logs -f

# Check EFS mount
df -h | grep efs
mount | grep efs

# Test S3 access
aws s3 ls s3://phil-foundryvtt/

# Check cron jobs
crontab -l
```

## Security Considerations
- SSH access limited to admin IPs only
- HTTP (port 80) open to world for game access
- HTTPS currently disabled (ACM/ALB resources commented out)
- Root EBS volume encrypted
- S3 bucket uses private ACL
- IAM follows least-privilege principle

## Future Enhancements (Commented Out)
- HTTPS support via ACM certificate and ALB
- Load balancer for better traffic management
- Multi-AZ deployment considerations

## Best Practices for AI Assistance
- When suggesting changes, always check impact on persistent data
- Provide complete code blocks, not partial snippets
- Include validation steps for suggested changes
- Warn about resources that require recreation
- Reference specific line numbers when discussing existing code
- Consider backup implications for destructive operations
