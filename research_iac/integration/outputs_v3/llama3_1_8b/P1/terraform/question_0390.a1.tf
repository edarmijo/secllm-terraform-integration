provider "aws" {
  region = "us-west-2"
}

# Create a secret for the ALB's SSL certificate
resource "aws_secretsmanager_secret" "alb_ssl_cert" {
  name = "alb-ssl-cert"
}

resource "aws_secretsmanager_secret_version" "alb_ssl_cert" {
  secret_id     = aws_secretsmanager_secret.alb_ssl_cert.id
  secret_string = <<EOF
{
  "certificate_arn": "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}
EOF
}

# Create an IAM role for the ALB
resource "aws_iam_role" "alb_role" {
  name        = "test-lb-tf-alb-role"
  description = "IAM role for the Application Load Balancer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancer.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "alb_policy" {
  name   = "test-lb-tf-alb-policy"
  role   = aws_iam_role.alb_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
        ]
        Resource = [
          aws_lb.test-lb-tf.arn,
          aws_lb.test-lb-tf.target_group_arns[0],
        ]
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforLoadBalancer"
}

# Create a security group for the ALB
resource "aws_security_group" "alb_sg" {
  name        = "test-lb-tf-alb-sg"
  description = "Security group for the Application Load Balancer"

  vpc_id = "vpc-12345678"

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

# Create a subnet for the ALB
resource "aws_subnet" "alb_subnet" {
  vpc_id            = "vpc-12345678"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

# Create an Application Load Balancer
resource "aws_lb" "test-lb-tf" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.alb_subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket        = "my-bucket"
    enabled       = true
    prefix        = "test-lb-tf"
  }
}