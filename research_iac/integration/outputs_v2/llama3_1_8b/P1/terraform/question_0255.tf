provider "aws" {
  region = var.aws_region
}

# Create a new VPC resource
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "example-vpc" }
}

# Create two subnets in the VPC
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_availability_zone
  tags              = { Name = "example-subnet-1" }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.aws_availability_zone
  tags              = { Name = "example-subnet-2" }
}

# Create a Redshift subnet group with the subnets
resource "aws_redshift_subnet_group" "example" {
  name       = "example-redshift-subnet-group"
  description = "Redshift subnet group for example cluster"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

# Create a Redshift cluster with the subnet group
resource "aws_redshift_cluster" "example" {
  cluster_identifier      = "example-redshift-cluster"
  node_type               = "dc2.large"
  number_of_nodes         = 1
  cluster_subnet_group_name = aws_redshift_subnet_group.example.name
}

# Create a Redshift endpoint access with the subnet group attached to the cluster
resource "aws_redshift_endpoint_access" "example" {
  cluster_identifier = aws_redshift_cluster.example.cluster_identifier
  vpc_security_group_ids = [aws_vpc.example.default_security_group_id]
}