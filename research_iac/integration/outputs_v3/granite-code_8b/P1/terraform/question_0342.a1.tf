# Configure the provider
provider "aws" {
  region = var.region
}

# Create a main VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

# Create two subnets in different availability zones
resource "aws_subnet" "subnet1" {
  cidr_block     = "10.0.1.0/24"
  availability_zone = var.availability_zones[0]
  vpc_id          = aws_vpc.main.id

  tags = {
    Environment = "dev"
  }
}

resource "aws_subnet" "subnet2" {
  cidr_block     = "10.0.2.0/24"
  availability_zone = var.availability_zones[1]
  vpc_id          = aws_vpc.main.id

  tags = {
    Environment = "dev"
  }
}

# Create a security group to allow database access
resource "aws_security_group" "database" {
  name        = "database-sg"
  description = "Allows database access"
  vpc_id      = aws_vpc.main.id

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

  tags = {
    Environment = "dev"
  }
}

# Create a PostgresSQL RDS instance
resource "aws_db_instance" "postgres" {
  identifier           = "my-postgres-db"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t4g.micro"
  storage_type         = "gp2"
  multi_az             = false
  publicly_accessible  = true
  skip_final_snapshot = true

  tags = {
    Environment = "dev"
  }
}

# Output the database endpoint for connectivity
output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}