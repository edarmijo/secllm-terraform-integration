provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_profile" {
  name        = "eb_ec2_profile"
  description = "Elastic Beanstalk EC2 instance profile"

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
  role   = aws_iam_role.eb_ec2_profile.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBParameters",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = aws_iam_role.eb_ec2_profile.name
  role = aws_iam_role.eb_ec2_profile.id
}

resource "aws_db_instance" "default" {
  allocated_storage     = 20
  engine                = "mysql"
  instance_class        = "db.t2.micro"
  name                  = "mydatabase"
  username              = "mydatabaseuser"
  password              = "mypassword"
  skip_final_snapshot   = true
}

resource "aws_elastic_beanstalk_environment" "default" {
  name                = "my-env"
  application         = aws_elastic_beanstalk_application.default.name
  version_label       = "v1"
  tier                = "webserver-medium"
  environment_name    = "my-env"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.default.id
  }

  setting {
    namespace = "aws:rds"
    name      = "DBInstanceIdentifier"
    value     = aws_db_instance.default.id
  }
}

resource "aws_elastic_beanstalk_application" "default" {
  name = "my-app"
}