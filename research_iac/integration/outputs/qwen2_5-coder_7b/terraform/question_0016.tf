provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "ec2_eb_profile1" {
  name = "ec2_eb_profile1"

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

resource "aws_iam_instance_profile" "ec2_eb_profile1" {
  name = "ec2_eb_profile1"
  roles = [aws_iam_role.ec2_eb_profile1.name]
}

resource "aws_db_instance" "my_db" {
  identifier        = "my_db"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  username          = "admin"
  password          = "password"
  allocated_storage = 20
}

resource "aws_elasticbeanstalk_environment" "blue" {
  application       = "my_app"
  environment_name  = "blue-env"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Python 3.8"
  instance_profile  = aws_iam_instance_profile.ec2_eb_profile1.name
  database          = {
    identifier        = aws_db_instance.my_db.identifier
    username          = aws_db_instance.my_db.username
    password          = aws_db_instance.my_db.password
  }
}

resource "aws_elasticbeanstalk_environment" "green" {
  application       = "my_app"
  environment_name  = "green-env"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Python 3.8"
  instance_profile  = aws_iam_instance_profile.ec2_eb_profile1.name
  database          = {
    identifier        = aws_db_instance.my_db.identifier
    username          = aws_db_instance.my_db.username
    password          = aws_db_instance.my_db.password
  }
}

resource "aws_db_snapshot" "my_db_snapshot" {
  db_instance_identifier = aws_db_instance.my_db.identifier
  db_snapshot_identifier = "my_db_snapshot"
}