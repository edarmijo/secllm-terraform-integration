provider "aws" {
  region = var.region
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

variable "availability_zone" {
  type        = string
  description = "The availability zone to use for the subnets"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  availability_zone = var.availability_zone

  tags = {
    Environment = "dev"
    Type        = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  availability_zone = var.availability_zone

  tags = {
    Environment = "dev"
    Type        = "private"
  }
}

resource "aws_redshift_subnet_group" "example" {
  name       = "example-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Environment = "dev"
  }
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier           = "example-cluster"
  node_type                    = "ds2.large"
  master_username              = "admin"
  master_password              = "password"
  skip_final_snapshot          = true

  subnet_group_name = aws_redshift_subnet_group.example.name

  tags = {
    Environment = "dev"
  }
}

resource "aws_redshift_endpoint_access" "example" {
  cluster_identifier = aws_redshift_cluster.example.id
  endpoint_name      = "example-endpoint"
  subnet_group_names = [aws_redshift_subnet_group.example.name]

  tags = {
    Environment = "dev"
  }
}