# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a new IAM role for the peering connection
resource "aws_iam_role" "pike_peering_role" {
  name        = "pike-peering-role"
  description = "Role for VPC peering connection"

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
resource "aws_iam_policy" "pike_peering_policy" {
  name        = "pike-peering-policy"
  description = "Policy for VPC peering connection"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AcceptVpcPeeringConnection",
          "ec2:RejectVpcPeeringConnection",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "pike_peering_attach" {
  role       = aws_iam_role.pike_peering_role.name
  policy_arn = aws_iam_policy.pike_peering_policy.arn
}

# Create a new VPC peering connection
resource "aws_vpc_peering_connection" "pike_peering_conn" {
  name               = "pike-peering-conn"
  vpc_id             = var.peer_vpc_id
  peer_vpc_id        = var.base_vpc_id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

# Create a new security group for the peering connection
resource "aws_security_group" "pike_peering_sg" {
  name        = "pike-peering-sg"
  description = "Security group for VPC peering connection"

  vpc_id = var.peer_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.base_cidr_block]
  }
}

# Create a new route table for the peering connection
resource "aws_route_table" "pike_peering_rt" {
  vpc_id = var.peer_vpc_id

  route {
    destination_cidr_block = var.base_cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.pike_peering_conn.id
  }
}

# Associate the security group with the route table
resource "aws_route_table_association" "pike_peering_assoc" {
  subnet_id     = var.peer_subnet_id
  route_table_id = aws_route_table.pike_peering_rt.id
}