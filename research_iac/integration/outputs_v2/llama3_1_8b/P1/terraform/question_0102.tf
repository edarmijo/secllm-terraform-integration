provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "example" {
  name        = "example-role"
  description = "EKS cluster role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  depends_on = [aws_iam_role.example]
}

data "aws_region" "current" {}

resource "aws_eks_cluster" "example" {
  name     = "example"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = ["subnet-12345678"]
    security_group_ids = [aws_security_group.example.id]
  }

  endpoint_private_access       = false
  endpoint_public_access        = true
  enable_log_types              = ["api", "authenticatord", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.example,
  ]
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 443"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_cluster_auth" "example" {
  cluster_name       = aws_eks_cluster.example.name
  disable_upload      = true

  depends_on = [
    aws_iam_role_policy_attachment.example,
  ]
}