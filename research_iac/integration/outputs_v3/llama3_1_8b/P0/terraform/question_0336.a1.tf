provider "aws" {
  region = "us-west-2"
}

resource "aws_security_group" "rds_sg" {
  name        = "airbyte-rds-sg"
  description = "Allow inbound traffic for RDS instance"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "airbyte_rds" {
  identifier           = "airbyte-rds-instance"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  username             = "airbyte"
  password             = "airbyte1234"
  skip_final_snapshot  = true
  apply_immediately    = true
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.airbyte_rds_sn.name
}

resource "aws_db_subnet_group" "airbyte_rds_sn" {
  name       = "airbyte-rds-sn-group"
  description = "RDS subnet group for Airbyte connector test cases"

  subnet_ids = [
    "subnet-12345678",
    "subnet-90123456"
  ]
}

resource "aws_rds_cluster_parameter_group" "airbyte_rds_pg" {
  name        = "airbyte-rds-pg"
  family      = "postgres15"
  description = "RDS parameter group for Airbyte connector test cases"

  parameter {
    name  = "autovacuum_vacuum_scale_factor"
    value = 0.1
  }

  parameter {
    name  = "autovacuum_analyze_scale_factor"
    value = 0.1
  }
}

resource "aws_rds_cluster" "airbyte_rds_cluster" {
  cluster_identifier = "airbyte-rds-cluster"
  engine             = "postgres"
  instance_class     = "db.t3.micro"
  database_name      = "airbyte"
  username           = "airbyte"
  password           = "airbyte1234"
  skip_final_snapshot = true
  apply_immediately   = true
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.airbyte_rds_sn.name
  parameter_group_name = aws_rds_cluster_parameter_group.airbyte_rds_pg.name
}