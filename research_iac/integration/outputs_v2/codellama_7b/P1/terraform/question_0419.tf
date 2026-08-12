provider "aws" {
  region = "us-east-1"
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "my-database-password"
  description = "Database password for my database"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = "my-database-password"
}

resource "aws_kms_key" "db_password_key" {
  description             = "Key for encrypting database passwords in Secrets Manager"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "db_password_key_alias" {
  name          = "alias/my-database-password-key"
  target_key_id = aws_kms_key.db_password_key.key_id
}

resource "aws_secretsmanager_secret_rotation" "db_password_rotation" {
  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_rules {
    automatically_after_days = 30
  }
}