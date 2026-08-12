provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "elastic_beanstalk_db_password" {
  name = "elastic-beanstalk-db-password"
}

resource "aws_iam_role" "elastic_beanstalk_exec_role" {
  name        = "${var.app_name}-elastic-beanstalk-exec-role"
  description = "Elastic Beanstalk execution role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "elastic_beanstalk_exec_policy" {
  name   = "${var.app_name}-elastic-beanstalk-exec-policy"
  role   = aws_iam_role.elastic_beanstalk_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.elastic_beanstalk_app.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "elastic_beanstalk_db_access_policy" {
  name   = "${var.app_name}-elastic-beanstalk-db-access-policy"
  role   = aws_iam_role.elastic_beanstalk_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect = "Allow"
        Resource = data.aws_secretsmanager_secret.elastic_beanstalk_db_password.arn
      }
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "elastic_beanstalk_env" {
  name                = var.app_name
  application         = aws_elastic_beanstalk_application.elastic_beanstalk_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.0.5 running Docker"

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
}

resource "aws_elastic_beanstalk_application" "elastic_beanstalk_app" {
  name        = var.app_name
  description = "Elastic Beanstalk application"

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
}

resource "aws_s3_bucket" "elastic_beanstalk_app" {
  bucket = var.app_name

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "elastic_beanstalk_app_policy" {
  bucket = aws_s3_bucket.elastic_beanstalk_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.elastic_beanstalk_app.arn}/*"
      }
    ]
  })
}