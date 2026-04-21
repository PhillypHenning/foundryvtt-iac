# Reference to existing ECS cluster
data "aws_ecs_cluster" "foundry_ecs_cluster" {
  cluster_name = split("/", var.ecs_cluster_arn)[1]
}

# ECS Task Definition
resource "aws_ecs_task_definition" "foundry_ecs_task" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.foundry_cpu
  memory                   = var.foundry_memory
  execution_role_arn       = aws_iam_role.foundry_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.foundry_ecs_task_role.arn

  volume {
    name = "foundry-efs-storage"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      authorization_config {
        iam = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "foundryvtt"
      image     = var.foundry_image
      essential = true

      portMappings = [
        {
          containerPort = var.foundry_port
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "foundry-efs-storage"
          containerPath = "/data"
          readOnly      = false
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:30000/api/status || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 180
      }

      environment = [
        {
          name  = "FOUNDRY_ADMIN_KEY"
          value = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["FOUNDRY_ADMIN_KEY"]
        },
        {
          name  = "FOUNDRY_USERNAME"
          value = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["FOUNDRY_USERNAME"]
        },
        {
          name  = "FOUNDRY_PASSWORD"
          value = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["FOUNDRY_PASSWORD"]
        },
        {
          name  = "FOUNDRY_LICENSE_KEY"
          value = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["FOUNDRY_LICENSE_KEY"]
        },
        {
          name  = "OPTIONS_SECRET_ARN"
          value = data.aws_secretsmanager_secret.foundry_options_file.arn
        },
        {
          name  = "FOUNDRY_AWS_CONFIG"
          value = "/data/Config/options.json"
        },
        {
          name  = "FOUNDRY_HOSTNAME"
          value = "${var.subdomain_name}.${var.domain_name}"
        }        
      ]
    }
  ])

  tags = {
    Name = "${var.project_name}-ecs-task"
  }
}

# -------------- #
# --- SERVICE ---#
# -------------- #
# ECS Service to run the task
resource "aws_ecs_service" "foundry_ecs_service" {
  name            = "${var.project_name}-service"
  cluster         = data.aws_ecs_cluster.foundry_ecs_cluster.id
  task_definition = aws_ecs_task_definition.foundry_ecs_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.foundry_ecs_task_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.foundry_tg.arn
    container_name   = "foundryvtt"
    container_port   = var.foundry_port
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  enable_execute_command = true

  depends_on = [aws_lb_listener.http]

  # Prevent Terraform from overriding the desired_count managed by scheduled auto-scaling
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name = "${var.project_name}-ecs-service"
  }
}
