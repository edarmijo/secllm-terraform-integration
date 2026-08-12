provider "aws" {
  region = "us-east-1"
}

resource "aws_subnet" "example1" {
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Example Subnet 1"
  }
}

resource "aws_subnet" "example2" {
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Example Subnet 2"
  }
}

resource "aws_neptune_cluster" "example" {
  cluster_identifier      = "example-neptune-cluster"
  engine                  = "neptune"
  master_username         = "admin"
  master_password         = var.master_password
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true

  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_group_name      = aws_neptune_subnet_group.example.name

  tags = {
    Name = "Example Neptune Cluster"
  }
}

resource "aws_neptune_subnet_group" "example" {
  name       = "example-neptune-subnet-group"
  subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]
}

resource "aws_security_group" "example" {
  name        = "example-neptune-sg"
  description = "Security group for example Neptune cluster"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 8182
    to_port     = 8182
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}