provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_cluster" "example" {
  engine                    = "aurora-postgresql"
  engine_version            = "15.6"
  instance_class             = "db.t3.micro"
  allocated_storage         = 5
  storage_encrypted         = true
  backup_retention_period   = 7
  preferred_backup_window   = "02:00-03:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"
}

resource "aws_rds_cluster_instance" "example" {
  identifier              = "example-cluster-instance"
  cluster_identifier      = aws_rds_cluster.example.id
  instance_class          = "db.t3.micro"
  engine                  = "aurora-postgresql"
  engine_version          = "15.6"
  allocated_storage       = 5
  storage_encrypted       = true
  backup_retention_period = 7
  preferred_backup_window = "02:00-03:00"
}