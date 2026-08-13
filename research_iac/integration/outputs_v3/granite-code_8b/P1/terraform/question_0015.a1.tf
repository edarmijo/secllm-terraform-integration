provider "aws" {
  region = var.region
}

resource "aws_db_instance" "prod_db" {
  identifier           = "prod_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  storage_type         = "gp2"
  multi_az             = false
  backup_retention_period = 7

  db_subnet_group_name = aws_db_subnet_group.prod_subnets.name
  security_group_ids    = [aws_security_group.prod_sg.id]
}

resource "aws_db_instance" "staging_db" {
  identifier           = "staging_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  storage_type         = "gp2"
  multi_az             = false
  backup_retention_period = 7

  db_subnet_group_name = aws_db_subnet_group.staging_subnets.name
  security_group_ids    = [aws_security_group.staging_sg.id]
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name = "EBPolicy"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::elasticbeanstalk-us-east-1-123456789012/*",
        "arn:aws:s3:::elasticbeanstalk-us-east-1-123456789012"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
  }
}