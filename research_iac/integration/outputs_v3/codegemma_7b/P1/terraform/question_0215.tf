provider "aws" {
  region = var.region
}

resource "aws_rds_cluster" "example" {
  cluster_identifier = "my-aurora-cluster"
  engine = "aurora"
  engine_version = "5.6.10a"

  availability_zones = var.availability_zones

  vpc_security_group_ids = var.security_group_ids

  database_name = "mydatabase"
  username = var.username
  password = var.password

  allocated_storage = 20
  storage_type = "gp2"
}