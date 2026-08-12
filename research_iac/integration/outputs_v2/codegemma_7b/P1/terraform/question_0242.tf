provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "neptune_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id = aws_vpc.neptune_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_b" {
  vpc_id = aws_vpc.neptune_vpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_neptune_cluster" "neptune_cluster" {
  cluster_identifier = "my-neptune-cluster"
  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}