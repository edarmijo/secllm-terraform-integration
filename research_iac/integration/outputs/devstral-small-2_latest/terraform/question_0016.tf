provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "my_db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
}

resource "aws_db_snapshot" "before_deployment" {
  db_instance_identifier = aws_db_instance.my_db.id

  depends_on = [aws_db_instance.my_db]
}

resource "aws_iam_role" "ec2_eb_role" {
  name = "ec2_eb_role"

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

resource "aws_iam_instance_profile" "ec2_eb_profile1" {
  name = "ec2_eb_profile1"
  role = aws_iam_role.ec2_eb_role.name
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "blue-environment"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_eb_profile1.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

resource "aws_elastic_beanstalk_environment" "green" {
  name                = "green-environment"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_eb_profile1.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

resource "aws_db_instance" "my_db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true

  depends_on = [aws_db_snapshot.before_deployment]
}