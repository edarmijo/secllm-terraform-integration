provider "aws" {
  region = var.region
}

resource "aws_db_subnet_group" "airbyte_test_subnets" {
  name       = "airbyte-test-subnets"
  subnet_ids = var.public_subnet_ids

  tags = {
    Environment = "dev"
  }
}

resource "aws_rds_cluster" "airbyte_test_db" {
  cluster_identifier      = "airbyte-test-db"
  engine                  = "postgres"
  engine_mode             = "SERVERLESS"
  master_username         = var.master_username
  master_user_password    = var.master_user_password
  skip_final_snapshot     = true
  apply_immediately      = true
  enable_http_endpoint   = true
  preferred_backup_window = "07:00-09:00"

  db_subnet_group_name = aws_db_subnet_group.airbyte_test_subnets.name

  tags = {
    Environment = "dev"
  }
}