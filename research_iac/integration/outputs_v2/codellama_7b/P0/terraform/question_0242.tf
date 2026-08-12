provider "aws" {
  region = "us-east-1"
}

resource "aws_subnet" "example1" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "example2" {
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_neptune_cluster" "example" {
  cluster_identifier = "example-neptune-cluster"
  engine             = "neptune"
  node_type          = "db.r5.large"
  storage_encrypted  = true
  vpc_security_group_ids = [aws_security_group.example.id]
  subnets            = [aws_subnet.example1.id, aws_subnet.example2.id]
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

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}