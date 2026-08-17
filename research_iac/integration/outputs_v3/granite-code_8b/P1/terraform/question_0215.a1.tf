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

resource "aws_aurora_cluster" "example" {
  cluster_identifier           = "example-aurora-cluster"
  engine                       = "aurora-mysql"
  engine_mode                  = "serverless"
  instance_class               = "db.t3.small"
  db_subnet_group_name         = aws_db_subnet_group.example.name
  skip_final_snapshot          = true
  backup_retention_period      = 7

  tags = {
    Environment = "dev"
  }
}