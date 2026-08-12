provider "aws" {
  region = "us-west-2"
}

resource "aws_kms_key" "example" {
  description             = "Example KMS key for Secrets Manager"
  deletion_window_in_days = 10
}

resource "aws_secretsmanager_secret" "example" {
  name                     = "example-db-secret"
  recovery_window_in_days  = 0
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username = "example-username"
    password = "example-password"
  })
}

resource "aws_rds_cluster_instance" "example" {
  cluster_identifier      = "example-cluster"
  database_name           = "example-db"
  instance_class          = "db.t2.micro"
  engine                  = "mysql"
  master_username         = var.master_username
  master_user_password    = aws_secretsmanager_secret_version.example.secret_string
  db_subnet_group_name    = aws_db_subnet_group.example.name
  vpc_security_group_ids  = [aws_security_group.example.id]
  kms_key_id              = aws_kms_key.example.arn

  depends_on = [
    aws_db_instance.example,
    aws_secretsmanager_secret_version.example
  ]
}

resource "aws_rds_cluster" "example" {
  cluster_identifier      = "example-cluster"
  database_name           = "example-db"
  master_username         = var.master_username
  master_user_password    = aws_secretsmanager_secret_version.example.secret_string
  vpc_security_group_ids  = [aws_security_group.example.id]
  kms_key_id              = aws_kms_key.example.arn

  depends_on = [
    aws_db_instance.example,
    aws_secretsmanager_secret_version.example
  ]
}

resource "aws_iam_role" "example" {
  name        = "example-rds-role"
  description = "Example IAM role for RDS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSServiceRolePolicyForRDSInstance"
}

resource "aws_db_instance" "example" {
  identifier           = "example-db-instance"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = var.master_username
  password             = aws_secretsmanager_secret_version.example.secret_string
  db_subnet_group_name = aws_db_subnet_group.example.name

  depends_on = [
    aws_rds_cluster_instance.example,
    aws_secretsmanager_secret_version.example
  ]
}

resource "aws_db_subnet_group" "example" {
  name       = "example-db-subnet-group"
  subnet_ids = [aws_subnet.example.id]
}