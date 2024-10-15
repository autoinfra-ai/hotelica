resource "aws_ecs_task_definition" "perplexica_task" {
  family                   = "perplexica-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "searxng-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.searxng_data.id
      root_directory = "/"
    }
  }

  container_definitions = jsonencode([
    {
      name  = "searxng"
      image = "docker.io/searxng/searxng:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/perplexica"
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "searxng"
        }
      }
      mountPoints = [
        {
          sourceVolume  = "searxng-data"
          containerPath = "/etc/searxng"
          readOnly      = false
        }
      ]
    },
    {
      name  = "perplexica-backend"
      image = "406515214055.dkr.ecr.us-east-2.amazonaws.com/perplexica-backend:latest"
      portMappings = [
        {
          containerPort = 3001
          hostPort      = 3001
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "SEARXNG_API_URL"
          value = "http://localhost:8080"
        }
      ]
      secrets = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = aws_ssm_parameter.OPENAI_API_KEY.arn
        },
        {
          name      = "DB_URL"
          valueFrom = aws_ssm_parameter.db_url.arn
        }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/perplexica"
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "backend"
        }
      }
    },
    {
      name  = "perplexica-frontend"
      image = "406515214055.dkr.ecr.us-east-2.amazonaws.com/perplexica-frontend:latest"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "NEXT_PUBLIC_WS_URL"
          value = "wss://airpursue.com/ws"
        },
        {
          name  = "NEXT_PUBLIC_API_URL"
          value = "https://airpursue.com/api"
        }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/perplexica"
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])
}
