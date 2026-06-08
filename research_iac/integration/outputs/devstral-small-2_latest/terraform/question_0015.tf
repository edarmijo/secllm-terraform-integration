provider "aws" {
  region = "us-east-1"
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

resource "aws_iam_role_policy_attachment" "eb_ec2_attach" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_db_instance" "prod_db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "prod_db"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "staging_db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  name                 = "staging_db"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
}

resource "aws_elastic_beanstalk_environment" "production" {
  name                = "production-env"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v5.8.0 running Node.js 18"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}

resource "aws_elastic_beanstalk_environment" "staging" {
  name                = "staging-env"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v5.8.0 running Node.js 18"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}