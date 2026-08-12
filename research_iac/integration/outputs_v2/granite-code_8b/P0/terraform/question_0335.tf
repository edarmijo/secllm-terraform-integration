provider "aws" {
  region = "us-east-1"
}

resource "aws_db_subnet_group" "airbyte_test_case_subnets" {
  name       = "airbyte_test_case_subnets"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
}

resource "aws_rds_cluster" "airbyte_test_case_postgres" {
  cluster_identifier           = "airbyte_test_case_postgres"
  engine                       = "postgres"
  engine_mode                  = "SERVERLESS"
  master_username              = "admin"
  master_password              = "password123"
  skip_final_snapshot          = true
  backup_ retention_period      = 0
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "mon:03:00-mon:05:00"
  db_subnet_group_name         = aws_db_subnet_group.airbyte_test_case_subnets.name
  storage_encrypted             = true

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "aws_rds_cluster_instance" "airbyte_test_case_postgres_instance" {
  cluster_identifier      = aws_rds_cluster.airbyte_test_case_postgres.id
  instance_class          = "db.t3.micro"
  allocated_storage       = 5
  storage_encrypted        = true
  skip_final_snapshot     = true
  auto_minor_version_upgrade = false

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}