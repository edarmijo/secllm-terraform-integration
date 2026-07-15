provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_profile" {
  name = "eb_ec2_profile"

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

resource "aws_iam_role_policy" "eb_ec2_profile_policy" {
  name   = "eb_ec2_profile_policy"
  role   = aws_iam_role.eb_ec2_profile.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:Connect",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_db_instance" "prod_db" {
  identifier             = "prod_db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "password123"
  parameter_group_name   = "default.mysql8.0"
}

resource "aws_db_instance" "staging_db" {
  identifier             = "staging_db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "password123"
  parameter_group_name   = "default.mysql8.0"
}