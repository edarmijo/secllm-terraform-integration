provider "aws" {
  region = var.region
}

resource "aws_aurora_cluster" "example" {
  cluster_identifier           = var.cluster_identifier
  engine                       = "mysql"
  engine_mode                  = "provisioned"
  instance_class               = "db.t3.small"
  storage_encrypted             = true
  backup_ retention_period      = 7
  skip_final_snapshot_before_creation = true

  db_subnet_group_name = aws_db_subnet_group.example.name
  vulnerability_scanning_configuration {
    enabled            = true
    scan_interval_in_minutes = 60
  }
}

resource "aws_aurora_global_cluster" "example" {
  cluster_identifier           = var.cluster_identifier
  engine                       = "mysql"
  engine_mode                  = "provisioned"
  instance_class               = "db.t3.small"
  storage_encrypted             = true
  backup_retention_period      = 7
  skip_final_snapshot_before_creation = true

  db_subnet_group_name = aws_db_subnet_group.example.name
  vulnerability_scanning_configuration {
    enabled            = true
    scan_interval_in_minutes = 60
  }
}