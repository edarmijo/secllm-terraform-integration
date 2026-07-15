provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_role" {
  name        = "eb_ec2_profile"
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
          "s3:*",
          "cloudwatch:*",
          "logs:*",
          "ec2:Describe*",
          "elasticbeanstalk:DescribeEnvironmentResources",
          "elasticbeanstalk:DescribeEvents",
          "elasticbeanstalk:DescribeInstancesHealth",
          "elasticbeanstalk:DescribeTaskDefinitions",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "eb_rds_role" {
  name        = "eb_rds_profile"
  description = "Elastic Beanstalk RDS role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eb_rds_policy" {
  name   = "eb_rds_policy"
  role   = aws_iam_role.eb_rds_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:Describe*",
          "rds:StartDBInstance",
          "rds:StopDBInstance",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                = "my-env-1"
  application         = aws_elastic_beanstalk_application.example.name
  tier                 = "webserver-medium"
  environment_name    = "my-env-1"

  setting {
    namespace = "aws:autoscaling:updatePolicy"
    name      = "ScalingAdjustment"
    value     = "100"
  }

  setting {
    namespace = "aws:autoscaling:updatePolicy:enabled"
    name      = "Cooldown"
    value     = "300"
  }

  setting {
    namespace = "aws:autoscaling:updatePolicy:enabled"
    name      = "ScalingAdjustment"
    value     = "100"
  }

  setting {
    namespace = "aws:ec2:instance"
    name      = "InstanceType"
    value     = "t3.medium"
  }
}

resource "aws_elastic_beanstalk_application" "example" {
  name        = "my-app-1"
  description = "My Elastic Beanstalk Application"
}

resource "aws_rds_cluster_instance" "example" {
  cluster_identifier      = aws_rds_cluster.example.id
  instance_class          = "db.t3.medium"
  engine                  = "mysql"
  database_name           = "my_db1"
  username                = "admin"
  password                = "password123"

  depends_on = [aws_elastic_beanstalk_environment.example]
}

resource "aws_rds_cluster" "example" {
  cluster_identifier      = "my-cluster-1"
  engine                  = "mysql"
  database_name           = "my_db1"
  master_username         = "admin"
  master_password         = "password123"

  vpc_security_group_ids = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = "allow_rds"
  description = "Allow RDS inbound traffic"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}