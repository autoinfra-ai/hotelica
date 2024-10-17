provider "aws" {
  region = "us-east-2"
}

# VPC and Networking
resource "aws_vpc" "perplexica_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "perplexica-vpc"
  }
}

resource "aws_subnet" "perplexica_subnet_1" {
  vpc_id                  = aws_vpc.perplexica_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "perplexica-subnet-1"
  }
}

resource "aws_subnet" "perplexica_subnet_2" {
  vpc_id                  = aws_vpc.perplexica_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "perplexica-subnet-2"
  }
}

resource "aws_internet_gateway" "perplexica_igw" {
  vpc_id = aws_vpc.perplexica_vpc.id

  tags = {
    Name = "perplexica-igw"
  }
}

resource "aws_route_table" "perplexica_rt" {
  vpc_id = aws_vpc.perplexica_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.perplexica_igw.id
  }

  tags = {
    Name = "perplexica-rt"
  }
}

resource "aws_route_table_association" "perplexica_rta_1" {
  subnet_id      = aws_subnet.perplexica_subnet_1.id
  route_table_id = aws_route_table.perplexica_rt.id
}

resource "aws_route_table_association" "perplexica_rta_2" {
  subnet_id      = aws_subnet.perplexica_subnet_2.id
  route_table_id = aws_route_table.perplexica_rt.id
}

# Security Group for ECS tasks
resource "aws_security_group" "perplexica_sg" {
  name        = "perplexica-sg"
  description = "Security group for Perplexica ECS tasks"
  vpc_id      = aws_vpc.perplexica_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    self        = true
  }
  # New rule to allow all internal traffic within the security group
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Specific IP rule (if still needed)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["192.184.250.198/32"]
    description = "Allow all TCP traffic from specific IP"
  }
}

# Add this rule after both security groups are created
resource "aws_security_group_rule" "perplexica_sg_from_db" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.hotelica_db_sg.id
  security_group_id        = aws_security_group.perplexica_sg.id
}

# Use data source to reference the existing Route 53 hosted zone
data "aws_route53_zone" "primary" {
  name         = "airpursue.com"
  private_zone = false
}

# ACM Certificate
resource "aws_acm_certificate" "perplexica_cert" {
  domain_name       = "airpursue.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS record for ACM certificate validation
resource "aws_route53_record" "perplexica_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.perplexica_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "perplexica_cert_validation" {
  certificate_arn         = aws_acm_certificate.perplexica_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.perplexica_cert_validation : record.fqdn]
}

# Load Balancer
resource "aws_lb" "perplexica_lb" {
  name               = "perplexica-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.perplexica_sg.id]
  subnets            = [aws_subnet.perplexica_subnet_1.id, aws_subnet.perplexica_subnet_2.id]

  enable_deletion_protection = true
  idle_timeout               = 1500  // Set to the maximum value of 4000 seconds (about 66 minutes)

  depends_on = [aws_internet_gateway.perplexica_igw]
}

# Frontend Target Group
resource "aws_lb_target_group" "perplexica_frontend_tg" {
  name        = "perplexica-frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.perplexica_vpc.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200-399"
  }
}

# Backend Target Group
resource "aws_lb_target_group" "perplexica_backend_tg" {
  name        = "perplexica-backend-tg"
  port        = 3001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.perplexica_vpc.id

  health_check {
    path                = "/api/health"  # Ensure this endpoint exists in your backend
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200-399"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
}

# HTTP Listener (Redirect to HTTPS)
resource "aws_lb_listener" "perplexica_listener_http" {
  load_balancer_arn = aws_lb.perplexica_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "perplexica_listener_https" {
  load_balancer_arn = aws_lb.perplexica_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.perplexica_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.perplexica_frontend_tg.arn
  }

  depends_on = [aws_acm_certificate_validation.perplexica_cert_validation]
}

# WebSocket Listener Rule
resource "aws_lb_listener_rule" "websocket" {
  listener_arn = aws_lb_listener.perplexica_listener_https.arn
  priority     = 90

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.perplexica_backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/ws", "/ws/*"]
    }
  }
}

# API Listener Rule
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.perplexica_listener_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.perplexica_backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "perplexica_cluster" {
  name = "perplexica-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Update the ECS Service to use the task definition from task_definition.tf
resource "aws_ecs_service" "perplexica_service" {
  name            = "perplexica-service"
  cluster         = aws_ecs_cluster.perplexica_cluster.id
  task_definition = aws_ecs_task_definition.perplexica_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 300
  enable_execute_command = true
  network_configuration {
    subnets          = [aws_subnet.perplexica_subnet_1.id, aws_subnet.perplexica_subnet_2.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.perplexica_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.perplexica_frontend_tg.arn
    container_name   = "perplexica-frontend"
    container_port   = 3000
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.perplexica_backend_tg.arn
    container_name   = "perplexica-backend"
    container_port   = 3001
  }

  depends_on = [aws_lb_listener.perplexica_listener_https]

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.perplexica_cluster.name}/${aws_ecs_service.perplexica_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "perplexica_logs" {
  name              = "/ecs/perplexica"
  retention_in_days = 30
}

# IAM Roles
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Consolidated IAM policy for ECS execution role
resource "aws_iam_policy" "ecs_execution_policy" {
  name        = "ecs_execution_policy"
  path        = "/"
  description = "Consolidated policy for ECS task execution including SSM, ECR, and CloudWatch Logs access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.perplexica_logs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.OPENAI_API_KEY.arn,
          aws_ssm_parameter.db_url.arn
        ]
      }
    ]
  })
  depends_on = [
    aws_ssm_parameter.db_url,
    aws_ssm_parameter.OPENAI_API_KEY
  ]
}

# Attach the consolidated policy to the ECS execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_policy.arn
}

# Attach the AmazonECSTaskExecutionRolePolicy to the ECS execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_default_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM policy for ECS task role
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "ecs_task_policy"
  path        = "/"
  description = "Policy for ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the ECS task policy to the ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# SSM Parameters
resource "aws_ssm_parameter" "OPENAI_API_KEY" {
  name  = "/perplexica/OPENAI_API_KEY"
  type  = "SecureString"
  value = var.OPENAI_API_KEY
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors ecs cpu utilization"
  alarm_actions       = [aws_appautoscaling_policy.ecs_policy_cpu.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.perplexica_cluster.name
    ServiceName = aws_ecs_service.perplexica_service.name
  }
}

# DNS record for the application
resource "aws_route53_record" "perplexica_alb" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "airpursue.com"
  type    = "A"

  alias {
    name                   = aws_lb.perplexica_lb.dns_name
    zone_id                = aws_lb.perplexica_lb.zone_id
    evaluate_target_health = true
  }
}

# New DNS record for the metrics subdomain
resource "aws_route53_record" "metrics_subdomain" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "metrics.airpursue.com"
  type    = "A"
  ttl     = 300
  records = ["52.14.165.31"]
}

resource "aws_efs_file_system" "searxng_data" {
  creation_token = "searxng-data"
  encrypted      = true

  tags = {
    Name = "SearxNG Data"
  }
}

# EFS Security Group
resource "aws_security_group" "efs_sg" {
  name        = "perplexica-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.perplexica_vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.perplexica_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Add this rule to the existing perplexica_sg
resource "aws_security_group_rule" "efs_outbound" {
  type              = "egress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.perplexica_vpc.cidr_block]
  security_group_id = aws_security_group.perplexica_sg.id
}

# Update the EFS mount targets to use the new security group
resource "aws_efs_mount_target" "searxng_data" {
  count           = 2
  file_system_id  = aws_efs_file_system.searxng_data.id
  subnet_id       = count.index == 0 ? aws_subnet.perplexica_subnet_1.id : aws_subnet.perplexica_subnet_2.id
  security_groups = [aws_security_group.efs_sg.id]
}
