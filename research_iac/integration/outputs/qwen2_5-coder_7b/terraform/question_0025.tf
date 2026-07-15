provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_profile3" {
  name = "eb_ec2_profile3"

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

resource "aws_iam_role_policy" "eb_ec2_profile3_policy" {
  name   = "eb_ec2_profile3_policy"
  role   = aws_iam_role.eb_ec2_profile3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:Connect",
          "elasticbeanstalk:Describe*",
          "ec2:Describe*",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  name                = "myenv_us_east"
  application         = aws_elastic_beanstalk_application.myapp_us_east.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"
  environment_type    = "SingleInstance"
  instance_profile    = aws_iam_role.eb_ec2_profile3.name

  option_settings = [
    {
      namespace        = "aws:elasticbeanstalk:environment"
      option_name      = "EnvironmentType"
      value            = "SingleInstance"
    },
    {
      namespace        = "aws:rdsdbinstance"
      option_name      = "DBInstanceClass"
      value            = "db.t2.micro"
    },
  ]
}

resource "aws_elastic_beanstalk_application" "myapp_us_east" {
  name        = "myapp_us_east"
  description = "My Application in US East"
}

resource "aws_db_instance" "main_db_us_east" {
  identifier             = "main_db_us_east"
  instance_class         = "db.t2.micro"
  engine                 = "mysql"
  engine_version         = "5.7"
  username               = "admin"
  password               = "password123"
  allocated_storage      = 20
  storage_type           = "gp2"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Security Group for RDS"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_zone" "mydomain" {
  name = "example.com"
}

resource "aws_route53_record" "us_east_alias" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = "us-east-1.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.myenv_us_east.endpoint
    zone_id                = aws_elastic_beanstalk_environment.myenv_us_east.vpc.id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "eu_west_alias" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = "eu-west-1.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.myenv_eu_west.endpoint
    zone_id                = aws_elastic_beanstalk_environment.myenv_eu_west.vpc.id
    evaluate_target_health = true
  }
}

resource "aws_elastic_beanstalk_environment" "myenv_eu_west" {
  name                = "myenv_eu_west"
  application         = aws_elastic_beanstalk_application.myapp_eu_west.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"
  environment_type    = "SingleInstance"
  instance_profile    = aws_iam_role.eb_ec2_profile3.name

  option_settings = [
    {
      namespace        = "aws:elasticbeanstalk:environment"
      option_name      = "EnvironmentType"
      value            = "SingleInstance"
    },
    {
      namespace        = "aws:rdsdbinstance"
      option_name      = "DBInstanceClass"
      value            = "db.t2.micro"
    },
  ]
}

resource "aws_elastic_beanstalk_application" "myapp_eu_west" {
  name        = "myapp_eu_west"
  description = "My Application in EU West"
}

resource "aws_db_instance" "main_db_eu_west" {
  identifier             = "main_db_eu_west"
  instance_class         = "db.t2.micro"
  engine                 = "mysql"
  engine_version         = "5.7"
  username               = "admin"
  password               = "password123"
  allocated_storage      = 20
  storage_type           = "gp2"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}