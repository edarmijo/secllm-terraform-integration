provider "aws" {
  region = "us-east-1"
}

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
  name        = "example-subnet-group"
  description = "Example Redshift subnet group"
  subnet_ids  = aws_subnet.example.*.id
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier   = "example-cluster"
  node_type            = "dc2.large"
  database_name        = "example"
  master_username      = "admin"
  master_password      = "Admin1234567890"
  cluster_subnet_group_name = aws_redshift_subnet_group.example.name
}

resource "aws_vpc_endpoint" "example" {
  vpc_id          = aws_vpc.example.id
  service_name    = "com.amazonaws.${var.region}.redshift"
  route_table_ids = [aws_route_table.example.id]
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id
}