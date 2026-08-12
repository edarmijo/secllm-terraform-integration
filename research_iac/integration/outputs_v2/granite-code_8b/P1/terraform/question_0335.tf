provider "aws" {
  region = var.region
}

resource "aws_db_subnet_group" "airbyte_test_subnets" {
  name       = "airbyte-test-subnets"
  subnet_ids = var.public_subnet_ids
}

resource "aws_rds_cluster" "airbyte_test_cluster" {
  engine        = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"
  storage_encrypted = true
  backup_Retention_period = 7

  db_subnet_group_name = aws_db_subnet_group.airbyte_test_subnets.name

  parameter_group_name = "default.postgres15"

  skip_final_snapshot_before_destroy = true
}

resource "aws_rds_cluster_instance" "airbyte_test_instance" {
  cluster_identifier      = aws_rds_cluster.airbyte_test_cluster.id
  instance_class          = "db.t3.micro"
  storage_encrypted        = true
  multi_az                 = false
  publicly_accessible       = false

  db_subnet_group_name = aws_db_subnet_group.airbyte_test_subnets.name
}