# FoundryVTT Custom Docker Image

This directory contains the Dockerfile and scripts for a custom FoundryVTT image with AWS CLI pre-installed.

## Building the Image

1. **Build the image:**
   ```bash
   docker build -t foundryvtt-aws:latest .
   ```

2. **Test locally:**
   ```bash
   docker run -p 30000:30000 \
     -e OPTIONS_SECRET_ARN=arn:aws:secretsmanager:... \
     -e AWS_DEFAULT_REGION=ca-central-1 \
     -e AWS_ACCESS_KEY_ID=... \
     -e AWS_SECRET_ACCESS_KEY=... \
     foundryvtt-aws:latest
   ```

## Pushing to ECR

1. **Create ECR repository:**
   ```bash
   aws ecr create-repository \
     --repository-name foundryvtt-aws \
     --region ca-central-1
   ```

2. **Login to ECR:**
   ```bash
   aws ecr get-login-password --region ca-central-1 | \
     docker login --username AWS --password-stdin \
     461706357402.dkr.ecr.ca-central-1.amazonaws.com
   ```

3. **Tag and push:**
   ```bash
   docker tag foundryvtt-aws:latest \
     461706357402.dkr.ecr.ca-central-1.amazonaws.com/foundryvtt-aws:latest
   
   docker push 461706357402.dkr.ecr.ca-central-1.amazonaws.com/foundryvtt-aws:latest
   ```

4. **Update terraform variable:**
   ```hcl
   foundry_image = "461706357402.dkr.ecr.ca-central-1.amazonaws.com/foundryvtt-aws:latest"
   ```

## What's Included

- AWS CLI v2 pre-installed
- Custom entrypoint that fetches options.json from Secrets Manager on startup
- All environment variables from original felddy/foundryvtt image
