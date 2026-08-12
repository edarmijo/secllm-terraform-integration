provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_profile"
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
  engine = "mysql" # Replace with your desired database engine
  engine_version = "8.0.28" # Replace with your desired database engine version
  instance_class = "db.t3.medium" # Replace with your desired database instance class
  allocated_storage = 20 # Replace with your desired database storage size in GB
  db_subnet_group_name = "your_db_subnet_group_name" # Replace with your desired database subnet group name
  vpc_security_group_ids = ["your_security_group_id"] # Replace with your desired security group ID
  iam_database_authentication_enabled = true
  enable_iam_database_authentication = true
  username = "your_db_username" # Replace with your desired database username
  password = "your_db_password" # Replace with your desired database password
}

resource "aws_rds_db_instance" "staging_db" {
  name = "staging_db"
  engine = "mysql" # Replace with your desired database engine
  engine_version = "8.0.28" # Replace with your desired database engine version
  instance_class = "db.t3.medium" # Replace with your desired database instance class
  allocated_storage = 20 # Replace with your desired database storage size in GB
  db_subnet_group_name = "your_db_subnet_group_name" # Replace with your desired database subnet group name
  vpc_security_group_ids = ["your_security_group_id"] # Replace with your desired security group ID
  iam_database_authentication_enabled = true
  enable_iam_database_authentication = true
  username = "your_db_username" # Replace with your desired database username
  password = "your_db_password" # Replace with your desired database password
}

resource "aws_elasticbeanstalk_application" "prod_app" {
  name = "prod_app"
}

resource "aws_elasticbeanstalk_environment" "prod_env" {
  name = "prod_env"
  application = aws_elasticbeanstalk_application.prod_app.name
  version_label = "your_app_version" # Replace with your desired application version label
  db_instances = [aws_rds_db_instance.prod_db.db_instance_identifier]
  tier {
    name = "WebServer"
    type = "Standard"
    version = "6.0"
  }
  instance_profile = aws_iam_instance_profile.eb_ec2_profile.name
}

resource "aws_elasticbeanstalk_application" "staging_app" {
  name = "staging_app"
}

resource "aws_elasticbeanstalk_environment" "staging_env" {
  name = "staging_env"
  application = aws_elasticbeanstalk_application.staging_app.name
  version_label = "your_app_version" # Replace with your desired application version label
  db_instances = [aws_rds_db_instance.staging_db.db_instance_identifier]
  tier {
    name = "WebServer"
    type = "Standard"
    version = "6.0"
  }
  instance_profile = aws_iam_instance_profile.eb_ec2_profile.name
}