# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Create an IAM role for the Memcached cluster
resource "aws_iam_role" "memcached_cluster_role" {
  name        = "memcached-cluster-role"
  description = "Role for the Memcached cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for the Memcached cluster
resource "aws_iam_policy" "memcached_cluster_policy" {
  name        = "memcached-cluster-policy"
  description = "Policy for the Memcached cluster"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "elasticache:CreateCacheCluster",
          "elasticache:CreateCacheParameterGroup",
          "elasticache:CreateCacheSubnetGroup",
          "elasticache:DeleteCacheCluster",
          "elasticache:DeleteCacheParameterGroup",
          "elasticache:DeleteCacheSubnetGroup",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "memcached_cluster_attach" {
  role       = aws_iam_role.memcached_cluster_role.name
  policy_arn = aws_iam_policy.memcached_cluster_policy.arn
}

# Create a Memcached cluster
resource "aws_elasticache_cluster" "memcached_cluster" {
  name           = "memcached-cluster"
  engine         = "memcached"
  port           = 11211
  num_cache_nodes = 1
  parameter_group_name = aws_elasticache_parameter_group.memcached_parameter.name
  subnet_group_name = aws_elasticache_subnet_group.memcached_subnet.name

  vpc_security_group_ids = [aws_security_group.memcached_sg.id]

  tags = {
    Name = "memcached-cluster"
  }
}

# Create a parameter group for the Memcached cluster
resource "aws_elasticache_parameter_group" "memcached_parameter" {
  name        = "memcached-parameter-group"
  family      = "memcached1.4"

  parameter {
    name  = "max_connections"
    value = "1000"
  }
}

# Create a subnet group for the Memcached cluster
resource "aws_elasticache_subnet_group" "memcached_subnet" {
  name       = "memcached-subnet-group"
  description = "Subnet group for the Memcached cluster"

  subnet_ids = [
    aws_subnet.memcached_subnet.id,
  ]
}

# Create a security group for the Memcached cluster
resource "aws_security_group" "memcached_sg" {
  name        = "memcached-sg"
  description = "Security group for the Memcached cluster"

  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a subnet for the Memcached cluster
resource "aws_subnet" "memcached_subnet" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "memcached-subnet"
  }
}

# Create a VPC for the Memcached cluster
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "default-vpc"
  }
}