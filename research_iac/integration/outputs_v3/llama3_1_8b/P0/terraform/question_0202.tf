provider "aws" {
  region = "us-east-2"
}

resource "aws_iam_role" "msk_cluster_role" {
  name        = "MSKClusterRole"
  description = "Allows MSK to manage related resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafka.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "msk_cluster_policy" {
  name   = "MSKClusterPolicy"
  role   = aws_iam_role.msk_cluster_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeDashboards",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_msk_cluster" "example" {
  cluster_name           = "example-cluster"
  kafka_version          = "2.6.1"
  number_of_broker_nodes = 3
  broker_node_type       = "kafka.m5.large"
  subnet_ids             = [aws_subnet.example.id]
  vpc_security_group_ids = [aws_security_group.example.id]

  configuration {
    arn      = aws_msk_configuration.example.arn
    revision = aws_msk_configuration.example.latest_revision
  }
}

resource "aws_msk_configuration" "example" {
  name       = "example-configuration"
  kafka_versions = ["2.6.1"]
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "example-subnet"
  }
}

resource "aws_security_group" "example" {
  name        = "example-security-group"
  description = "Allow inbound traffic on port 9094"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vpc"
  }
}