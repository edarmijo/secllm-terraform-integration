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

resource "aws_iam_role_policy" "eb_ec2_profile_policy" {
  name = "eb_ec2_profile_policy"
  role = aws_iam_role.eb_ec2_profile.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ec2:AttachVolume",
        "ec2: DetachVolume"
      ],
      "Resource": "*",
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_db_instance" "prod_db" {
  identifier           = "prod_db"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_db_instance" "staging_db" {
  identifier           = "staging_db"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.default.name
}