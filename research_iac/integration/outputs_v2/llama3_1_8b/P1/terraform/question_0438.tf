provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "db_credentials" {
  name = "database-credentials"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-public-rtb"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id     = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id     = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_region == "us-west-2" ? "us-west-2a" : "eu-central-1a"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.aws_region == "us-west-2" ? "us-west-2b" : "eu-central-1b"

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_security_group" "db_access" {
  name        = "database-access-sg"
  description = "Allow access to MySQL and PostgreSQL databases"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  description = "Database subnet group for RDS instances"

  subnet_ids = [aws_subnet.public1.id, aws_subnet.public2.id]
}