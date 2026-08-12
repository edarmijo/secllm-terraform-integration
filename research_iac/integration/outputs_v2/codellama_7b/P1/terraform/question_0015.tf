provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_profile" {
  name        = "eb_ec2_profile"
  description = "IAM role for Elastic Beanstalk EC2 instances"

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

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = aws_iam_role.eb_ec2_profile.name
}

resource "aws_db_instance" "prod_db" {
  identifier           = "prod-db"
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = var.prod_db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "staging_db" {
  identifier           = "staging-db"
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = var.staging_db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_elastic_beanstalk_environment" "production" {
  name        = "production-env"
  application = aws_elastic_beanstalk_application.example.name
  tier        = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.arn
  }
}

resource "aws_elastic_beanstalk_environment" "staging" {
  name        = "staging-env"
  application = aws_elastic_beanstalk_application.example.name
  tier        = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.arn
  }
}