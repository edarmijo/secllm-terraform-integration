provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eb_ec2_profile" {
  name               = "eb_ec2_profile"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "eb_ec2_profile" {
  name   = "eb_ec2_profile"
  role   = aws_iam_role.eb_ec2_profile.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_password" {
  role       = aws_iam_role.eb_ec2_profile.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

resource "aws_db_instance" "default" {
  identifier           = "eb-default-rds"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "admin"
  password             = aws_secretsmanager_secret_version.rds_password.secret_string
  vpc_security_group_ids = [aws_security_group.default.id]
}

resource "aws_security_group" "default" {
  name        = "eb-default-sg"
  description = "Allow inbound traffic on port 3306"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
}

resource "aws_elastic_beanstalk_environment" "default" {
  name                = "eb-default-env"
  application         = aws_elastic_beanstalk_application.default.name
  environment_name    = "dev"
  tier                = "webserver-medium"
  version_label       = "v1"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${var.subnet_ids}"
  }

  depends_on = [
    aws_db_instance.default,
  ]
}

resource "aws_elastic_beanstalk_application" "default" {
  name        = "eb-default-app"
  description = "Elastic Beanstalk application for default environment"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }
}

resource "aws_secretsmanager_secret" "rds_password" {
  name        = "RDS_Password"
  description = "Password for RDS instance"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = "your_rds_password_here"
}