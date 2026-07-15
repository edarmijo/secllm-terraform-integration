provider "aws" {
  region = "us-east-1"
}

resource "aws_db_subnet_group" "example" {
  name       = "example-db-subnet-group"
  subnet_ids = ["subnet-034e6787e9c4a81fa", "subnet-b7d581c0844f29050"]
}

resource "aws_rds_cluster" "example" {
  cluster_identifier           = "example-cluster"
  engine                       = "postgres"
  engine_mode                  = "SERVERLESS"
  master_username              = "foo"
  master_password              = "bar"
  skip_final_snapshot          = true
  backup_ retention_period      = 0
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "mon:03:00-mon:05:00"
  db_subnet_group_name         = aws_db_subnet_group.example.name

  serverless_v2_scaling_configuration {
    max_ capacity = 1000
    min_capacity = 100
  }
}