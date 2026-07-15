provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_profile1" {
  name = "eb_ec2_profile1"

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

resource "aws_iam_role_policy_attachment" "eb_ec2_profile1_elasticbeanstalk_webtier" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkWebTier"
  role       = aws_iam_role.eb_ec2_profile1.name
}

resource "aws_rds_db_instance" "myapp_db" {
  identifier             = "myapp_db"
  instance_class         = "db.t3.micro"
  engine                 = "mysql"
  engine_version         = "5.7"
  username               = "admin"
  password               = "password123"
  allocated_storage      = 20
  storage_type           = "gp2"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.myapp_db_sg.id]
}

resource "aws_security_group" "myapp_db_sg" {
  name        = "myapp_db_sg"
  description = "Security group for RDS instance"

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

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = "www"
  type    = "A"
  ttl     = 300

  alias {
    name                   = aws_elastic_beanstalk_environment.myenv.endpoint
    zone_id                = aws_elastic_beanstalk_environment.myenv.vpc_config.elb_dns_name
    evaluate_target_health = true
  }
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  application       = aws_elastic_beanstalk_application.myapp.name
  environment_name  = "myenv"
  solution_stack_name = "64bit Amazon Linux 2 v3.5.1 running Python 3.8"

  option_settings = [
    {
      namespace        = "aws:elasticbeanstalk:environment"
      option_name      = "EnvironmentType"
      value            = "SingleInstance"
    },
    {
      namespace        = "aws:rds:dbinstance"
      option_name      = "DBInstanceIdentifier"
      value            = aws_rds_db_instance.myapp_db.identifier
    },
  ]

  instance_profile = aws_iam_role.eb_ec2_profile1.name
}

resource "aws_elastic_beanstalk_application" "myapp" {
  name        = "myapp"
  description = "My Elastic Beanstalk Application"
}