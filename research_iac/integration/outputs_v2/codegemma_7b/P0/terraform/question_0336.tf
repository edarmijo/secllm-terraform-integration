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
  name                = "airbyte-db"
  engine              = "postgresql15"
  engine_version      = "15.2"
  publicly_accessible = true
  skip_final_snapshot = true

  vpc_security_group_ids = [
    # Replace with actual security group IDs
  ]

  subnet_ids = [
    # Replace with actual subnet IDs
  ]

  iam_database_authentication_enabled = true
  database_name                      = "airbyte"

  apply_immediately = true

  provisioner "local-exec" {
    command = "aws rds modify-db-cluster --db-cluster-identifier airbyte-db --apply-immediately"
  }
}