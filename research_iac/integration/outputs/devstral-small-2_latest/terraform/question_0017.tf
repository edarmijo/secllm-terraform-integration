provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_ec2_ssm" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_elastic_beanstalk_environment" "eb_env" {
  name                = "eb-env"
  application         = aws_elastic_beanstalk_application.eb_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "80"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "20"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "4"
  }
}

resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = "eb-app"
  description = "EB App with RDS"
}

resource "aws_db_instance" "my_db1" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  identifier             = "my-db-1"
  name                   = "mydb"
  username               = "admin"
  password               = "password123"
  skip_final_snapshot    = true
}

resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = "eb-app"
  description = "EB App with RDS"
}