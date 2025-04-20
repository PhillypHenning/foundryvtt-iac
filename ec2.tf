######################
## FOUNDRY INSTANCE ##
######################
resource "aws_instance" "foundry_instance" {
  depends_on    = [aws_s3_object.options_json]
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
    aws s3 cp ${var.s3_instance_config_uri}/options.json /home/ec2-user/foundry/options.json
    aws s3 cp ${var.s3_instance_config_uri}/secrets.json /home/ec2-user/foundry/secrets.json

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
          - FOUNDRY_HOSTNAME=${var.subdomain_name}.${var.domain_name}
    EOL

    # Start the service
    sudo docker-compose up -d
  EOF
}
######################

################
## Elastic IP ##
################
resource "aws_eip" "foundry_eip" {
  instance = aws_instance.foundry_instance.id
  domain   = "vpc"
}
################
