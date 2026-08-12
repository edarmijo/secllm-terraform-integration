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

resource "aws_rds_db_instance" "prod_db" {
  name = "prod_db"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  db_subnet_group_name = "your_db_subnet_group_name"
  vpc_security_group_ids = ["your_security_group_id"]
  iam_database_authentication_enabled = true
  enable_iam_database_authentication = true
  master_username = "your_master_username"
  master_password = var.prod_db_password
}

resource "aws_rds_db_instance" "staging_db" {
  name = "staging_db"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  db_subnet_group_name = "your_db_subnet_group_name"
  vpc_security_group_ids = ["your_security_group_id"]
  iam_database_authentication_enabled = true
  enable_iam_database_authentication = true
  master_username = "your_master_username"
  master_password = var.staging_db_password
}

resource "aws_elasticbeanstalk_environment" "production" {
  name = "production"
  application = "your_application_name"
  version_label = "your_version_label"
  solution_stack_name = "64bit Amazon Linux 2 with PHP 7.4"
  db_instances = [aws_rds_db_instance.prod_db.db_instance_identifier]
  instance_profile = aws_iam_instance_profile.eb_ec2_profile.name
}

resource "aws_elasticbeanstalk_environment" "staging" {
  name = "staging"
  application = "your_application_name"
  version_label = "your_version_label"
  solution_stack_name = "64bit Amazon Linux 2 with PHP 7.4"
  db_instances = [aws_rds_db_instance.staging_db.db_instance_identifier]
  instance_profile = aws_iam_instance_profile.eb_ec2_profile.name
}