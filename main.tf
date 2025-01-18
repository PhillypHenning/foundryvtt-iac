data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

data "aws_security_group" "selected" {
  id = "sg-0b4306f19233f1240"
}

resource "aws_security_group" "allow_specific_ips" {
  name        = "allow-specific-ips"
  description = "Allow specific IP addresses"

  ingress {
    description = "Allow HTTP access for Allowed IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "Allow HTTP access for admin IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.admin_ips
  }

  ingress {
    description = "Allow SSH access for admin IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_ips
  }

  ingress {
    description = "Allow NFS access from default VPC in ca-central-1"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic for Allowed IPs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "instance_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy to allow S3 access to specific bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::phil-foundryvtt",
          "arn:aws:s3:::phil-foundryvtt/InstanceConfig/01172025/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_access" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.instance_role.name
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_instance" "foundry_instance" {
  ami           = "ami-0956b8dc6ddc445ec"
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [
    aws_security_group.allow_specific_ips.name,
    data.aws_security_group.selected.name
  ]
  root_block_device {
    encrypted = true
  }
  hibernation = true
  tags = {
    Name = "FoundryVTT"
  }
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  user_data            = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker aws-cli
    sudo dnf install libxcrypt-compat -y
    systemctl start docker
    systemctl enable docker
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    mkdir -p /home/ec2-user/foundry
    cd /home/ec2-user/foundry

    # Create EFS mount point
    mkdir -p /mnt/efs

    # Mount the EFS file system using your known EFS DNS name
    mount -t nfs4 -o nfsvers=4.1 ${var.efs_safehouse}:/ /mnt/efs

    # Ensure the EFS mount persists across reboots
    echo "${var.efs_safehouse}:/ /mnt/efs nfs4 defaults,_netdev 0 0" >> /etc/fstab

    # Create a symlink for easier access
    ln -s /mnt/efs /home/ec2-user/foundry/data

    # Retrieve JSON config files from S3
    aws s3 cp s3://phil-foundryvtt/InstanceConfig/01172025/options.json /home/ec2-user/foundry/options.json
    aws s3 cp s3://phil-foundryvtt/InstanceConfig/01172025/secrets.json /home/ec2-user/foundry/secrets.json

    # Writing the Docker Compose file directly into a file
    cat > /home/ec2-user/foundry/docker-compose.yml <<EOL
    ---
    version: "3.8"

    secrets:
      config_json:
        file: secrets.json

    services:
      foundry:
        image: felddy/foundryvtt:release
        hostname: my_foundry_host
        restart: "no"
        volumes:
          - type: bind
            source: ./data
            target: /data
          - type: bind
            source: ./options.json
            target: /data/Config/awsOptions.json
        ports:
          - target: 30000
            published: 80
            protocol: tcp
            mode: host
        secrets:
          - source: config_json
            target: config.json
        environment:
          # - CONTAINER_PRESERVE_CONFIG=false
          - CONTAINER_VERBOSE=true
          - FOUNDRY_AWS_CONFIG=awsOptions.json
          - TIMEZONE=US/Eastern
          - FOUNDRY_PROXY_PORT=80
          - FOUNDRY_HOSTNAME=edge-of-the-universe-foundryvtt.ca
    EOL

    # Start the service
    sudo docker-compose up -d
  EOF
}

resource "aws_route53_record" "foundryvtt_record" {
  zone_id = data.aws_route53_zone.selected.zone_id

  name = "${var.subdomain_name}.${var.domain_name}"
  type = "A"
  ttl  = "300"

  # Associate the public IP of the EC2 instance
  records = [aws_instance.foundry_instance.public_ip]
}
