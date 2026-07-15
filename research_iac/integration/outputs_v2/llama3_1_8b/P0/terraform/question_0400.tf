provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "gateway_load_balancer_exec" {
  name        = "GatewayLoadBalancerExecRole"
  description = "Execution role for the Gateway Load Balancer"

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

resource "aws_iam_role_policy" "gateway_load_balancer_exec" {
  name   = "GatewayLoadBalancerExecPolicy"
  role   = aws_iam_role.gateway_load_balancer_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:ModifyInstanceAttribute",
          "ec2:ReplaceRoute",
          "ec2:ReplaceRouteTableAssociation",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_security_group" "gateway_load_balancer_sg" {
  name        = "GatewayLoadBalancerSG"
  description = "Security group for the Gateway Load Balancer"

  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "gateway_load_balancer" {
  name            = "GatewayLoadBalancer"
  subnets         = aws_subnet.default.*.id
  security_groups = [aws_security_group.gateway_load_balancer_sg.id]
}

resource "aws_alb_target_group" "gateway_load_balancer_tg" {
  name     = "GatewayLoadBalancerTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id

  health_check {
    enabled         = true
    healthy_threshold = 3
    unhealthy_threshold = 10
    timeout       = 5
    interval      = 10
    path          = "/"
    port          = 80
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

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "default" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-west-2a"
}