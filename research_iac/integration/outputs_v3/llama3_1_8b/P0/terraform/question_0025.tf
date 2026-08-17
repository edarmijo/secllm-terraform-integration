provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

resource "aws_iam_role" "eb_ec2_profile3" {
  name               = "eb_ec2_profile3"
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

resource "aws_iam_role_policy" "eb_ec2_policy3" {
  name   = "eb_ec2_policy3"
  role   = aws_iam_role.eb_ec2_profile3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::myapp-us-east-1",
          "arn:aws:s3:::myapp-eu-west-1",
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:logs:us-east-1:*:*",
          "arn:aws:logs:eu-west-1:*:*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "rds_policy" {
  name   = "rds_policy"
  role   = aws_iam_role.eb_ec2_profile3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBParameters",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:rds:us-east-1:*:*",
          "arn:aws:rds:eu-west-1:*:*",
        ]
      },
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  name                = "myenv-us-east"
  application         = aws_elastic_beanstalk_application.myapp_us_east.name
  environment_name    = "myenv-us-east"
  tier_name           = "WebServer"
  version_label       = "v1"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCID"
    value     = aws_vpc.default.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "SubnetIds"
    value     = aws_subnet.default.id
  }
}

resource "aws_elastic_beanstalk_environment" "myenv_eu_west" {
  name                = "myenv-eu-west"
  application         = aws_elastic_beanstalk_application.myapp_eu_west.name
  environment_name    = "myenv-eu-west"
  tier_name           = "WebServer"
  version_label       = "v1"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCID"
    value     = aws_vpc.default.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "SubnetIds"
    value     = aws_subnet.default.id
  }
}

resource "aws_elastic_beanstalk_application" "myapp_us_east" {
  name = "myapp-us-east"
}

resource "aws_elastic_beanstalk_application" "myapp_eu_west" {
  name = "myapp-eu-west"
}

resource "aws_db_instance" "main_db_us_east" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "main_db_us_east"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.default.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_db_instance" "main_db_eu_west" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "main_db_eu_west"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.default.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_security_group" "default" {
  name        = "default"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "default" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.default.id
  availability_zone = "us-east-1a"
}

resource "aws_db_subnet_group" "default" {
  name       = "default"
  subnet_ids = [aws_subnet.default.id]
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "us_east_alias" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "us-east.example.com"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.myenv_us_east.endpoint_url
    zone_id                = aws_route53_zone.example.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "eu_west_alias" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "eu-west.example.com"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.myenv_eu_west.endpoint_url
    zone_id                = aws_route53_zone.example.zone_id
    evaluate_target_health = false
  }
}