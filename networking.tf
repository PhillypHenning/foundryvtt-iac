data "aws_security_group" "selected" {
  id = var.default_security_group
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

  # ingress {
  #   description = "Allow HTTPS access for Allowed IPs"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = var.allowed_ips
  # }

  ingress {
    description = "Allow HTTP access for admin IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.admin_ips
  }

  # ingress {
  #   description = "Allow HTTPS access for admin IPs"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = var.admin_ips
  # }

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
