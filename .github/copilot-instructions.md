# FoundryVTT Infrastructure as Code - Copilot Instructions

## Project Overview
This repository manages the infrastructure deployment for a FoundryVTT game server on AWS. The project contains multiple implementation approaches:

- **ec2/** - Original EC2-based implementation (legacy)
- **ecs/** - New ECS-based implementation (current development focus)

## Architecture Evolution

### EC2 Implementation (Legacy - ec2/)
The original implementation uses:
- EC2 instance running FoundryVTT in Docker
- External EFS mount for persistent game data storage
- S3 bucket for configuration, assets, and backups
- Route53 DNS configuration
- See `ec2/copilot-instructions.md` for detailed EC2 implementation guidance

### ECS Implementation (New - ecs/)
The new implementation will use:
- ECS Fargate for serverless container orchestration
- EFS for persistent game data storage
- S3 bucket for configuration, assets, and backups
- Application Load Balancer for traffic management
- Route53 DNS configuration
- Auto-scaling and improved availability

## Development Guidelines

### General Principles
1. **Data Persistence**: Always protect EFS - game data must persist across deployments
2. **State Management**: Terraform backend state stored in S3 bucket `ph-terraform-state-bucket`
3. **Region Consistency**: Primary region is `ca-central-1`
4. **Security**: Never expose resources publicly without explicit admin approval
5. **Secrets**: Never commit sensitive files (terraform.tfvars, secrets.json, etc.)

### Code Style
- Use clear resource naming with implementation prefixes (e.g., `foundry_ecs_*`, `foundry_ec2_*`)
- Always include `depends_on` for implicit dependencies
- Add descriptive comments for complex configurations
- Keep scripts and user_data readable with clear sections
- Use variables for all configurable values
- Document all architectural decisions

### Working Between Implementations
- EC2 and ECS implementations may share some resources (EFS, S3, Route53)
- Be explicit about which implementation is being modified
- Test changes don't affect the other implementation
- Consider migration path when suggesting changes

## Current Focus: ECS Implementation

When working on the ECS implementation, prioritize:
1. Container orchestration best practices
2. Stateless container design with EFS integration
3. High availability and fault tolerance
4. Cost optimization with Fargate
5. Security with task roles and security groups
6. Blue-green deployment capabilities

## File Structure

### Root Level
- `.github/copilot-instructions.md` - This file
- `README.md` - Main project documentation
- Shared configuration files as needed

### EC2 Implementation
- `ec2/` - All EC2-specific Terraform code and configurations
- `ec2/copilot-instructions.md` - Detailed EC2 implementation guidance

### ECS Implementation
- `ecs/` - All ECS-specific Terraform code and configurations (to be created)

## Testing Approach
1. Always run `terraform plan` before `terraform apply`
2. Validate changes don't affect persistent data (EFS)
3. Test in non-production environment when possible
4. Verify DNS resolution after Route53 changes
5. Monitor application health after deployment changes

## Security Considerations
- Follow principle of least privilege for IAM roles
- Use security groups to restrict network access
- Encrypt data at rest and in transit
- Keep secrets in AWS Secrets Manager or Parameter Store
- Regular security audits of exposed resources

## Best Practices for AI Assistance
- Always specify which implementation (EC2 or ECS) is being discussed
- Check impact on persistent data before suggesting changes
- Provide complete code blocks with context
- Include validation steps for suggested changes
- Warn about resources that require recreation
- Consider cost implications of infrastructure changes
- Reference specific files and line numbers when discussing existing code
