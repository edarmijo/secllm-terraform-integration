provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine                    = "mysql"
  allocated_storage         = 20
  instance_class            = "db.t3.micro"
  name                      = "example"
  username                  = "admin"
  password                  = data.aws_secretsmanager_secret_version.example.secret_string
  kms_key_id                = aws_kms_key.example.arn
}

resource "aws_secretsmanager_secret" "example" {
  name = "example-password"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({ "username": "admin", "password": "mysecretpassword" })
}

resource "aws_kms_key" "example" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 7
}