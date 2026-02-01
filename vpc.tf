# Reference the default VPC
data "aws_vpc" "default" {
  default = true
}

# Reference existing subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "foundry_ecs_task_sg" {
  name        = "${var.project_name}-ecs-task-sg"
  description = "Security group for FoundryVTT ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "FoundryVTT from ALB"
    from_port       = var.foundry_port
    to_port         = var.foundry_port
    protocol        = "tcp"
    security_groups = [aws_security_group.foundry_alb_sg.id]
  }

  ingress {
    description = "NFS for EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-task-sg"
  }
}
