provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
}

resource "aws_secrets_manager_secret" "db_password" {
  name = "db_password"
  description = "Database password"

  generate_secret = true
  secret_string_template = jsonencode({
    username = "db_user"
    password = ""
  })

  kms_key_id = "YOUR_KMS_KEY_ID"
}

resource "aws_rds_db_instance" "db_instance" {
  name = "db_instance"
  engine = "mysql"
  engine_version = "8.0.27"

  allocated_storage = 20
  instance_class = "db.t3.medium"

  master_username = "db_user"
  master_password = aws_secrets_manager_secret.db_password.secret_string

  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_security_group" "db_sg" {
  name = "db_sg"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["YOUR_CIDR_BLOCK"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}