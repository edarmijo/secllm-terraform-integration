provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = var.rds_password_secret_id
}

resource "aws_rds_cluster_instance" "airbyte_connector_test" {
  cluster_identifier      = "airbyte-connector-test-cluster"
  instance_class          = "db.t3.micro"
  engine                  = "postgres"
  database_name           = "airbyte_db"
  username                = "airbyte_user"
  password                = jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)["RDS_PASSWORD"]
  publicly_accessible     = true
  vpc_security_group_ids  = [aws_security_group.airbyte_connector_test.id]
  db_subnet_group_name    = aws_db_subnet_group.airbyte_connector_test.name

  tags = {
    Name        = "airbyte-connector-test-instance"
    Environment = "dev"
  }
}

resource "aws_security_group" "airbyte_connector_test" {
  name        = "airbyte-connector-test-sg"
  description = "Allow inbound traffic on PostgreSQL port for Airbyte connector test cases"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.airbyte_connector_test_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "airbyte_connector_test" {
  name       = "airbyte-connector-test-sg"
  description = "Subnet group for Airbyte connector test cases"

  subnet_ids = [var.public_subnet_id, var.public_subnet_id]
}