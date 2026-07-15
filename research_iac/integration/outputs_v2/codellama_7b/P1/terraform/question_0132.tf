provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Example VPC"
  }
}

resource "aws_subnet" "example" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.example.id
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Example security group"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami           = "ami-abc123456"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example.id
  security_groups = [aws_security_group.example.name]
}

resource "aws_elasticache_cluster" "example" {
  cluster_id           = "example-memcached"
  engine               = "memcached"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.memcached1.4"
}