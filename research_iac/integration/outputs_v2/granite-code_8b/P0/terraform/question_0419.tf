resource "aws_db_instance" "example" {
  engine           = "mysql"
  instance_class   = "db.t2.small"
  name             = "example-database"
  username         = "admin"
  password         = aws_secretsmanager_secret_version.master_password.secret_string
  storage_encrypted = true
  kms_key_id       = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "dev"
  }
}

resource "aws_secretsmanager_secret" "master_password" {
  name                 = "example-database-master-password"
  description          = "Managed Master Password for example-database"
  kms_key_id           = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  generate_secret_string = {
    exclude_characters  = "\"',@/#\\[]{}?=-&+^~*()%&$;:"
    password_length      = 16
    secret_string_template = '{"username": "admin", "password": "${password}"}'
  }
}