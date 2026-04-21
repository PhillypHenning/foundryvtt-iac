# EFS mount targets each have a network interface with a known description.
# We look them up to discover their security group IDs without needing to
# hardcode them or import the mount target resources.
data "aws_network_interfaces" "efs" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "description"
    values = ["EFS mount target for ${var.efs_file_system_id}"]
  }
}

data "aws_network_interface" "efs" {
  for_each = toset(data.aws_network_interfaces.efs.ids)
  id       = each.value
}

locals {
  efs_security_group_ids = toset(distinct(flatten([
    for ni in data.aws_network_interface.efs : ni.security_groups
  ])))
}

# Add NFS access from the EC2 security group to each EFS mount target SG.
# Uses aws_vpc_security_group_ingress_rule (not inline rules) so it doesn't
# conflict with any other Terraform state managing those SGs.
resource "aws_vpc_security_group_ingress_rule" "efs_nfs_from_ec2" {
  for_each = local.efs_security_group_ids

  security_group_id            = each.value
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.foundryvtt.id
  description                  = "NFS from FoundryVTT EC2"
}
