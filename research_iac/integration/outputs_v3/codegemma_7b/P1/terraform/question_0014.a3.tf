provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  role = aws_iam_role.eb_ec2_role.name
}

variable "db_password" {
  type = string
  default = "your_password"
}

resource "aws_db_instance" "default" {
  name = "default"
  engine = "postgres"
  engine_version = "14.2"
  allocated_storage = 20
  instance_class = "db.t2.micro"
  username = "postgres"
  password = var.db_password
  vpc_security_group_ids = [aws_security_group.default.id]
}

resource "aws_security_group" "default" {
  name = "default"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elastic_beanstalk_environment" "default" {
  name = "default"
  application = "my_app"
  version = "latest"

  option_settings {
    namespace = "aws:elasticbeanstalk:environment:process"
    option_name = "ServerSideConfiguration"
    value = "server.config"
  }

  option_settings {
    namespace = "aws:elasticbeanstalk:application:environment"
    option_name = "DatabaseConnectionSetting"
    value = "host=${aws_db_instance.default.endpoint},port=5432,dbname=${aws_db_instance.default.db_name},user=${aws_db_instance.default.username},password=${var.db_password}"
  }

  instance_profile = aws_iam_instance_profile.eb_ec2_profile.name
}