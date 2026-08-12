provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_database" "example" {
  name        = "my-managed-database"
  engine      = "mysql"
  master_username = "root"
  master_password = "MyPassword123!"
  allocated_storage = 50
  backup_retention_days = 7
}