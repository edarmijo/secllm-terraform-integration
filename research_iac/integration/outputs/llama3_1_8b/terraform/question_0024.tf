provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_role" {
  name        = "eb_ec2_role"
  description = "Elastic Beanstalk EC2 role"

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

resource "aws_iam_role_policy" "eb_ec2_policy" {
  name   = "eb_ec2_policy"
  role   = aws_iam_role.eb_ec2_role.id

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
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile1" {
  name = "eb_ec2_profile1"

  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  name                = "myenv"
  application         = "myapp"
  description         = "My Elastic Beanstalk environment"
  tier                = "webserver-medium"
  platform            = "64bit Amazon Linux 2 v3.0.5 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.default.*.id
  }
}

resource "aws_rds_cluster" "myapp_db" {
  cluster_identifier      = "myapp-db-cluster"
  engine                  = "aurora-postgresql"
  instance_class          = "db.r5.large"
  database_name           = "myapp"
  master_username         = "admin"
  master_password         = "password"

  vpc_security_group_ids = [aws_security_group.default.id]

  tags = {
    Name        = "myapp-db-cluster"
    Environment = "dev"
  }
}

resource "aws_route53_zone" "mydomain" {
  name            = "example.com."
  comment         = "Managed by Terraform"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "mydomain_alias" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = aws_elastic_beanstalk_environment.myenv.endpoint_url
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.myenv.endpoint_url
    zone_id                = aws_elastic_beanstalk_environment.myenv.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "mydomain_alias_db" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = aws_rds_cluster.myapp_db.endpoint
  type    = "A"
  alias {
    name                   = aws_rds_cluster.myapp_db.endpoint
    zone_id                = aws_rds_cluster.myapp_db.zone_id
    evaluate_target_health = false
  }
}