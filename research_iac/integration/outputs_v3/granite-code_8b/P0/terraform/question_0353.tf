provider "aws" {
  region = var.region
}

resource "aws_db_subnet_group" "example" {
  name       = "example-db-subnet-group"
  subnet_ids = [aws_subnet.example.*.id]

  tags = {
    Environment = "dev"
  }
}

resource "aws_rds_cluster" "example" {
  cluster_identifier           = "example-aurora-cluster"
  engine                       = "aurora-mysql"
  engine_mode                  = "provisioned"
  instances                    = 2
  instance_class               = "db.r5.large"
  master_username              = "admin"
  master_user_password         = aws_secretsmanager_secret.master_password.arn
  skip_final_snapshot          = true
  storage_encrypted             = true
  backup_ retention_period      = 7
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "mon:03:00-mon:05:00"
  subnet_group                 = aws_db_subnet_group.example.name
  vulnerability_scan_status    = "disabled"

  tags = {
    Environment = "dev"
  }
}

resource "aws_secretsmanager_secret" "master_password" {
  name = "example-aurora-cluster-master-password"

  tags = {
    Environment = "dev"
  }
}

resource "aws_secretsmanager_secret_version" "master_password" {
  secret_id     = aws_secretsmanager_secret.master_password.id
  secret_string = "example_password"
}

resource "aws_rds_cluster_proxy" "example" {
  name            = "example-aurora-cluster-proxy"
  cluster_identifier = aws_rds_cluster.example.id
  engine_family    = "MYSQL"
  auth             = ["SECRETS"]

  tags = {
    Environment = "dev"
  }
}