provider "aws" {
  region = "us-east-1"
}

resource "aws_db_subnet_group" "example" {
  name       = "example-db-subnet-group"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  tags = {
    Environment = "production"
  }
}

resource "aws_security_group" "example" {
  name        = "example-db-sg"
  description = "Example DB Security Group"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_db_instance" "example" {
  identifier           = "example-db"
  engine               = "postgres"
  engine_version       = "9.4.5"
  instance_class       = "db.t2.small"
  storage_type         = "gp2"
  allocated_storage    = 50
  max_allocated_storage = 50

  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  security_groups = [
    aws_security_group.example.id,
  ]

  maintenance_window = "mon:00:00-mon:03:00"

  tags = {
    Environment = "production"
  }
}