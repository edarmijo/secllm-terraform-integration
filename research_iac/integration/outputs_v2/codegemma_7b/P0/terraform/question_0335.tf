provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "airbyte_role" {
  name = "airbyte-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "airbyte_role_policy" {
  role       = aws_iam_role.airbyte_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_rds_cluster" "airbyte_db" {
  engine                 = "postgresql15"
  engine_version         = "15.2"
  allocated_storage      = 5
  instance_type          = "db.t3.micro"
  publicly_accessible    = true
  vpc_security_group_ids = ["sg-0123456789abcdef01"]
  subnet_ids             = ["subnet-0123456789abcdef01", "subnet-0fedcba9876543210"]
  iam_database_authentication_enabled = true
  enable_iam_database_authentication = true
  master_username        = "airbyte"
  master_password        = "strongpassword"
}