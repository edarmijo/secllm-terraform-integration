provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
}

resource "aws_secretsmanager_secret" "rds_password" {
  name = "Airbyte-RDS-Password"
}

resource "aws_rds_cluster_instance" "airbyte_postgres" {
  cluster_identifier      = "airbyte-postgres-cluster"
  instance_class          = "db.t3.medium"
  engine                  = "postgres"
  engine_version          = "15.0"
  database_name           = "airbyte"
  username                = var.rds_username
  password                = data.aws_secretsmanager_secret_version.rds_password.secret_string
  publicly_accessible     = true
  skip_final_snapshot     = true
  apply_immediately       = true

  vpc_security_group_ids = [aws_security_group.airbyte_postgres.id]

  depends_on = [
    aws_db_instance.airbyte_postgres,
  ]
}

resource "aws_rds_cluster" "airbyte_postgres" {
  cluster_identifier      = "airbyte-postgres-cluster"
  database_name           = "airbyte"
  master_username         = var.rds_username
  master_user_password    = data.aws_secretsmanager_secret_version.rds_password.secret_string

  vpc_security_group_ids = [aws_security_group.airbyte_postgres.id]

  depends_on = [
    aws_db_instance.airbyte_postgres,
  ]
}

resource "aws_security_group" "airbyte_postgres" {
  name        = "airbyte-postgres-sg"
  description = "Allow inbound traffic on PostgreSQL port"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.airbyte_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "airbyte_postgres" {
  identifier           = "airbyte-postgres-instance"
  instance_class       = "db.t3.medium"
  engine               = "postgres"
  engine_version        = "15.0"
  username             = var.rds_username
  password             = data.aws_secretsmanager_secret_version.rds_password.secret_string
  publicly_accessible  = true

  vpc_security_group_ids = [aws_security_group.airbyte_postgres.id]

  skip_final_snapshot     = true
  apply_immediately       = true

  depends_on = [
    aws_rds_cluster_instance.airbyte_postgres,
  ]
}