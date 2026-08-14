provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "example2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_redshift_subnet_group" "example" {
  name       = "example-subnet-group"
  description = "Subnet group for Redshift cluster"

  subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Security group for Redshift cluster"

  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier      = "example-cluster"
  node_type               = "dc2.large"
  number_of_nodes         = 1
  database_name           = "mydb"
  master_username         = "myuser"
  master_password         = "mypassword"
  vpc_security_group_ids  = [aws_security_group.example.id]
  subnet_ids              = [aws_subnet.example1.id, aws_subnet.example2.id]

  tags = {
    Name        = "example-cluster"
    Environment = "dev"
  }
}

resource "aws_redshift_cluster" "endpoint_example" {
  cluster_identifier      = "example-endpoint-cluster"
  node_type               = "dc2.large"
  number_of_nodes         = 1
  database_name           = "mydb"
  master_username         = "myuser"
  master_password         = "mypassword"
  vpc_security_group_ids  = [aws_security_group.example.id]
  subnet_ids              = [aws_subnet.example1.id, aws_subnet.example2.id]

  tags = {
    Name        = "example-endpoint-cluster"
    Environment = "dev"
  }
}