# Configure AWS Provider
provider "aws" {
  region = var.region
}

# Create IAM Role for DynamoDB Global Table
resource "aws_iam_role" "dynamodb_global_table_role" {
  name        = "${var.name}-dynamodb-global-table-role"
  description = "IAM role for DynamoDB Global Table"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM Policy for DynamoDB Global Table
resource "aws_iam_policy" "dynamodb_global_table_policy" {
  name        = "${var.name}-dynamodb-global-table-policy"
  description = "IAM policy for DynamoDB Global Table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:UpdateTable",
          "dynamodb:DeleteTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Effect = "Allow"
        Resource = aws_dynamodb_table.dynamodb_global_table.arn
      },
      {
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Effect = "Allow"
        Resource = aws_ec2_security_group.dynamodb_global_table_sg.arn
      }
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "dynamodb_global_table_attach" {
  role       = aws_iam_role.dynamodb_global_table_role.name
  policy_arn = aws_iam_policy.dynamodb_global_table_policy.arn
}

# Create DynamoDB Global Table
resource "aws_dynamodb_table" "dynamodb_global_table" {
  name           = var.name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  global_secondary_index {
    name         = "gsi1"
    hash_key     = "gsi1_hash_key"
    range_key     = "gsi1_range_key"
  }

  replica {
    region_name = var.region
  }
}

# Create Security Group for DynamoDB Global Table
resource "aws_security_group" "dynamodb_global_table_sg" {
  name        = "${var.name}-dynamodb-global-table-sg"
  description = "Security group for DynamoDB Global Table"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.dynamodb_global_table_vpc.cidr_block]
  }
}

# Create VPC for DynamoDB Global Table
resource "aws_vpc" "dynamodb_global_table_vpc" {
  name        = "${var.name}-dynamodb-global-table-vpc"
  cidr_block  = "10.0.0.0/16"

  tags = {
    Name = "${var.name}-dynamodb-global-table-vpc"
  }
}