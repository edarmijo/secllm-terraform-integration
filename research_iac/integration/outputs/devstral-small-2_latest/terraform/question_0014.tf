provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password123"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_iam_role" "eb_role" {
  name = "eb-role"

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

resource "aws_iam_role_policy_attachment" "eb_attach" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_role.name
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "my-env"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_role.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:database"
    name      = "DBInstanceClass"
    value     = "db.t3.micro"
  }

  setting {
    namespace = "aws:elasticbeanstalk:database"
    name      = "DBEngine"
    value     = "mysql"
  }

  setting {
    namespace = "aws:elasticbeanstalk:database"
    name      = "DBUser"
    value     = aws_db_instance.default.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:database"
    name      = "DBPassword"
    value     = aws_db_instance.default.password
  }
}