provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_profile" {
  name               = "eb_ec2_profile"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eb_ec2_profile_policy_attachment" {
  role       = aws_iam_role.eb_ec2_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkFullAccess"
}

resource "aws_rds_instance" "prod_db" {
  identifier           = "prod_db"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.default.name

  backup_Retention_period = 7
}

resource "aws_rds_instance" "staging_db" {
  identifier           = "staging_db"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.default.name

  backup_retention_period = 7
}