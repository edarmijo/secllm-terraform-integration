provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_open_id_connect_provider" "example_oidc" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint      = "1234567890abcdef"
  url             = "https://example.eks.us-west-2.amazonaws.com"
  client_id       = "arn:aws:iam::123456789012:oidc-provider/example"
  identity_provider_config_name  = "example_oidc_config"
}

resource "aws_eks_cluster" "example" {
  name                = "example"
  role_arn            = aws_iam_role.example.arn
  vpc_config {
    subnet_ids = ["subnet-12345678", "subnet-90123456"]
  }
}

resource "aws_iam_role" "example" {
  name        = "example-cluster-role"
  description = "EKS Cluster Role for example cluster"

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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}