provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_cluster" "airbyte_test_db" {
  engine = "postgresql15"
  engine_mode = "serverless"
  skip_final_snapshot = true
  apply_immediately = true

  vpc_security_group_ids = ["sg-0123456789abcdef01"]

  database_name = "airbyte_test_db"

  # Remove these arguments as they are not supported for serverless clusters
  # subnet_ids = ["subnet-0123456789abcdef02", "subnet-0123456789abcdef03"]
  # username = var.db_username
  # password = var.db_password
}