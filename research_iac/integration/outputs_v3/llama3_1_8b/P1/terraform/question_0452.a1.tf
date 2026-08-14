# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a new VPC for peering (peer)
resource "aws_vpc" "peer" {
  cidr_block = "10.0.0.0/24"
  tags       = { Name = "peer-vpc" }
}

# Create a new VPC for peering (base)
resource "aws_vpc" "base" {
  cidr_block = "10.1.0.0/24"
  tags       = { Name = "base-vpc" }
}

# Create an IAM role for the peering connection
resource "aws_iam_role" "pike_peering" {
  name        = "pike-peering-role"
  description = "Role for VPC peering connection pike"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc.amazonaws.com"
        }
      },
    ]
  })
}

# Create an IAM policy for the peering connection
resource "aws_iam_policy" "pike_peering" {
  name        = "pike-peering-policy"
  description = "Policy for VPC peering connection pike"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "ec2:AcceptVpcPeeringConnection",
        Effect = "Allow",
        Resource = aws_vpc.peer.id
      },
      {
        Action = "ec2:CreateTags",
        Effect = "Allow",
        Resource = aws_vpc.peer.id
      },
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "pike_peering" {
  role       = aws_iam_role.pike_peering.name
  policy_arn = aws_iam_policy.pike_peering.arn
}

# Create a VPC peering connection
resource "aws_vpc_peering_connection" "pike" {
  name               = "pike-peering"
  vpc_id             = aws_vpc.peer.id
  peer_vpc_id        = aws_vpc.base.id
  auto_accept        = true

  tags = {
    Name = "pike-peering"
    pike = "permissions"
  }
}

# Declare the input variable for AWS account ID
variable "aws_account_id" {
  type = string
}