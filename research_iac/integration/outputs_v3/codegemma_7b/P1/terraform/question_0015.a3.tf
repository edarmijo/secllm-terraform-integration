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

resource "aws_db_subnet_group" "your_subnet_group_name" {
  name = "your_subnet_group_name"
  subnet_ids = ["your_subnet_ids"]
}

resource "aws_db_security_group" "your_security_group_name" {
  name = "your_security_group_name"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["your_cidr_blocks"]
  }
}

resource "aws_db_instance" "prod_db" {
  name = "prod_db"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.your_subnet_group_name.name
  vpc_security_group_ids = [aws_db_security_group.your_security_group_name.id]
}

resource "aws_db_instance" "staging_db" {
  name = "staging_db"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.your_subnet_group_name.name
  vpc_security_group_ids = [aws_db_security_group.your_security_group_name.id]
}

resource "aws_elastic_beanstalk_application" "your_application_name" {
  name = "your_application_name"
}

resource "aws_elastic_beanstalk_environment" "production" {
  name = "production"
  application = aws_elastic_beanstalk_application.your_application_name.name
  version_label = "your_version_label"
  db_instances = [aws_db_instance.prod_db.db_instance_identifier]
  instance_profile_name = aws_iam_instance_profile.eb_ec2_profile.name
}

resource "aws_elastic_beanstalk_environment" "staging" {
  name = "staging"
  application = aws_elastic_beanstalk_application.your_application_name.name
  version_label = "your_version_label"
  db_instances = [aws_db_instance.staging_db.db_instance_identifier]
  instance_profile_name = aws_iam_instance_profile.eb_ec2_profile.name
}