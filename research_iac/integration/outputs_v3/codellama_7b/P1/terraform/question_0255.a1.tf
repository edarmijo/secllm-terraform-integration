provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "master_password" {}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

resource "aws_redshift_subnet_group" "example" {
  name       = "example-subnet-group"
  subnet_ids = aws_subnet.example.*.id
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier   = "example-cluster"
  node_type            = "dc2.large"
  database_name        = "mydb"
  master_username      = "foo"
  master_password      = var.master_password
  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_group_name    = aws_redshift_subnet_group.example.name
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic for Redshift cluster"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}