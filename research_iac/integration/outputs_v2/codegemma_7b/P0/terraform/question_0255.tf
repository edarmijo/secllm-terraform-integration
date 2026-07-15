provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example_subnet_1" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "example_subnet_2" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_redshift_subnet_group" "example_subnet_group" {
  name = "example_subnet_group"
  subnet_ids = [aws_subnet.example_subnet_1.id, aws_subnet.example_subnet_2.id]
}

resource "aws_redshift_cluster" "example_cluster" {
  cluster_identifier = "example_cluster"
  database_name = "example_database"
  master_username = "example_user"
  master_password = "example_password"
  subnet_group_name = aws_redshift_subnet_group.example_subnet_group.name
}

resource "aws_redshift_endpoint_access" "example_endpoint_access" {
  cluster_identifier = aws_redshift_cluster.example_cluster.cluster_identifier
  subnet_group_name = aws_redshift_subnet_group.example_subnet_group.name
}