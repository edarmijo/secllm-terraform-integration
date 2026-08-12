provider "aws" {
  region = "us-east-1"
}

resource "aws_secrets_manager_secret" "master_password" {
  name = "master_password"

  generate_data = base64encode(random_password.master_password.result)

  kms_key_id = "<your_kms_key_id>"
}

resource "aws_database_instance" "database" {
  name = "my_database"
  engine = "mysql"
  engine_version = "8.0"

  master_username = "admin"
  master_password = aws_secrets_manager_secret.master_password.secret_arn

  allocated_storage = 20
  instance_class = "db.t2.micro"

  vpc_security_group_ids = ["<your_security_group_id>"]
  subnet_ids = ["<your_subnet_id>"]
}