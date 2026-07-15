provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "gateway_load_balancer_exec_role" {
  name        = "${var.environment}-glb-exec-role"
  description = "Execution role for Gateway Load Balancer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "gateway_load_balancer_exec_policy" {
  name   = "${var.environment}-glb-exec-policy"
  role   = aws_iam_role.gateway_load_balancer_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "gateway_load_balancer_exec_profile" {
  name = "${var.environment}-glb-exec-profile"
  role = aws_iam_role.gateway_load_balancer_exec_role.name
}

data "aws_secretsmanager_secret" "glb_api_key" {
  name = var.glb_api_key_secret_name
}

resource "aws_security_group" "gateway_load_balancer_sg" {
  name        = "${var.environment}-glb-sg"
  description = "Security group for Gateway Load Balancer"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "gateway_load_balancer" {
  name            = "${var.environment}-glb"
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.gateway_load_balancer_sg.id]
}

resource "aws_alb_target_group" "gateway_load_balancer_tg" {
  name     = "${var.environment}-glb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 30
    path                = "/"
  }
}

resource "aws_alb_listener" "gateway_load_balancer_listener" {
  load_balancer_arn = aws_alb.gateway_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.gateway_load_balancer_tg.arn
    type             = "forward"
  }
}