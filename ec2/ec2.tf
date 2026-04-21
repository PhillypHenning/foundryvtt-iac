data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "foundryvtt" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.foundryvtt.id]
  iam_instance_profile   = aws_iam_instance_profile.foundryvtt.name
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    efs_file_system_id       = var.efs_file_system_id
    aws_region               = var.aws_region
    foundry_image            = var.foundry_image
    foundry_secrets_arn      = var.foundry_secrets_arn
    foundry_options_file_arn = var.foundry_options_file_arn
    subdomain_name           = var.subdomain_name
    domain_name              = var.domain_name
  }))

  # IMDSv2 with hop limit of 2 so the Docker container can reach instance metadata
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-ec2"
  }

  # Replace instance if user_data changes (triggers new AMI lookup + fresh bootstrap)
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "foundryvtt" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-eip" }
}

resource "aws_eip_association" "foundryvtt" {
  instance_id   = aws_instance.foundryvtt.id
  allocation_id = aws_eip.foundryvtt.id
}
