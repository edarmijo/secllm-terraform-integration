# Create a new AWS VPC
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Environment = "dev"
  }
}

# Create two subnets in the new VPC
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Environment = "dev"
    Type        = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Environment = "dev"
    Type        = "private"
  }
}

# Create a new AWS Redshift subnet group
resource "aws_redshift_subnet_group" "example" {
  name       = "example-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]

  tags = {
    Environment = "dev"
  }
}

# Create a new AWS Redshift cluster
resource "aws_redshift_cluster" "example" {
  cluster_identifier           = "example-cluster"
  database_name                = "mydb"
  master_username              = "admin"
  master_password              = "MySuperSecretPassword123!"
  node_type                    = "ds2.large"
  number_of_nodes              = 2
  subnet_group_name            = aws_redshift_subnet_group.example.name
  encrypted                    = true
  skip_final_snapshot          = true

  tags = {
    Environment = "dev"
  }
}

# Create a new AWS Redshift endpoint access
resource "aws_redshift_endpoint_access" "example" {
  cluster_identifier = aws_redshift_cluster.example.id
  resource_owner      = "self"

  tags = {
    Environment = "dev"
  }
}