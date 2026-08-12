# Create an AWS database using managed master passwords and a specific KMS key

resource "aws_db_instance" "example" {
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  name                 = "example-db"
  username             = "admin"
  password             = data.aws_secretsmanager_secret_version.master_password.secret_string
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.example.arn
  skip_final_snapshot  = true

  db_subnet_group_name = aws_db_subnet_group.example.name
}

data "aws_secretsmanager_secret" "master_password" {
  name = "example-master-password"
}

data "aws_secretsmanager_secret_version" "master_password" {
  secret_id = data.aws_secretsmanager_secret.master_password.id
}

resource "aws_kms_key" "example" {
  description = "KMS key for encrypting the database password"
  enable_key_rotation = true

  tags = {
    Environment = "production"
  }
}