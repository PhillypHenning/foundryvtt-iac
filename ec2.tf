######################
## FOUNDRY INSTANCE ##
######################
resource "aws_instance" "foundry_instance" {
  depends_on        = [aws_s3_object.options_json]
  availability_zone = var.aws_preferred_zone
  ami               = "ami-0956b8dc6ddc445ec"
  instance_type     = var.instance_type
  key_name          = var.key_name
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
    yum install -y docker aws-cli cronie
    sudo dnf install libxcrypt-compat -y
    
    # Starting docker
    systemctl start docker
    systemctl enable docker

    # Starting cron
    service crond start
    chkconfig crond on

    # Installing docker-compose
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
    chown -R 1000:1000 /home/ec2-user/foundry/data/

    # Retrieve JSON config files from S3
    aws s3 cp s3://${var.s3_bucket}/${var.s3_instance_config}/options.json /home/ec2-user/foundry/options.json
    aws s3 cp s3://${var.s3_bucket}/${var.s3_instance_config}/secrets.json /home/ec2-user/foundry/secrets.json

    # Writing the Docker Compose file directly into a file
    cat > /home/ec2-user/foundry/docker-compose.yml <<EOL
    ---
    version: "3.8"

    secrets:
      config_json:
        file: secrets.json

    services:
      foundry:
        image: felddy/foundryvtt:release-13.342.0
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



data "template_file" "backup_script" {
  template = <<-EOT
    #!/bin/bash
    DATA_DIR="${var.worlds_data_dir}"
    S3_BUCKET="${var.s3_bucket}"
    S3_SNAPSHOT_DIRECTORY="${var.s3_snapshot_directory}"
    DATE=$(date +"%Y-%m-%d_%H-%M-%S")
    ZIP_FILE="/tmp/data-backup-$DATE.zip"

    zip -r "$ZIP_FILE" "$DATA_DIR"
    if [ $? -ne 0 ]; then
      echo "Zipping failed!"
      exit 1
    fi
    
    aws s3 cp "$ZIP_FILE" "s3://$S3_BUCKET/$S3_SNAPSHOT_DIRECTORY/"
    if [ $? -ne 0 ]; then
      echo "Upload failed!"
      exit 1
    fi
    
    echo "Backup and upload completed successfully."
    rm -f "$ZIP_FILE"
  EOT
  vars = {
    worlds_data_dir       = var.worlds_data_dir
    s3_bucket             = var.s3_bucket
    s3_snapshot_directory = var.s3_snapshot_directory
  }
}


resource "null_resource" "cron_backup" {
  depends_on = [aws_instance.foundry_instance]

  provisioner "file" {
    content     = data.template_file.backup_script.rendered
    destination = "/home/ec2-user/backup_to_s3.sh"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.foundry_instance.public_ip
    }
  }

  # So it reruns if we change the script content or cron timing
  triggers = {
    script_content = data.template_file.backup_script.rendered
    cron_timing    = "0 3 * * 0"
    force          = "04052025" # Update this to force recreation
  }

  provisioner "remote-exec" {
    inline = [
      # Ensure the script is executable
      "chmod +x /home/ec2-user/backup_to_s3.sh",

      # Install the cronjob if not present (appends if missing)
      "(crontab -l 2>/dev/null | grep -v '/home/ec2-user/backup_to_s3.sh'; echo '0 3 * * 0 /home/ec2-user/backup_to_s3.sh >> /home/ec2-user/backup_to_s3.log 2>&1') | crontab -"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.foundry_instance.public_ip
    }
  }
}
