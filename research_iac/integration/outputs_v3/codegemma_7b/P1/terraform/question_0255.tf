provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Example VPC"
  }
}

resource "aws_subnet" "example_subnet_a" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Example Subnet A"
  }
}

resource "aws_subnet" "example_subnet_b" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Example Subnet B"
  }
}

resource "aws_redshift_subnet_group" "example_subnet_group" {
  name = "Example Subnet Group"
  subnet_ids = [aws_subnet.example_subnet_a.id, aws_subnet.example_subnet_b.id]
}

resource "aws_redshift_cluster" "example_cluster" {
  cluster_type = "single-node"
  db_name = "example_db"
  master_username = "example_user"
  master_password = var.example_password
  subnet_group_name = aws_redshift_subnet_group.example_subnet_group.name

  tags = {
    Name = "Example Redshift Cluster"
  }
}

resource "aws_redshift_endpoint_access" "example_endpoint_access" {
  cluster_identifier = aws_redshift_cluster.example_cluster.cluster_identifier
  subnet_group_name = aws_redshift_subnet_group.example_subnet_group.name

  tags = {
    Name = "Example Redshift Endpoint Access"
  }
}