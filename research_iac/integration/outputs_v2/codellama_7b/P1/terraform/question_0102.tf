provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "example" {
  name            = "example"
  role_arn        = aws_iam_role.example.arn
  private_subnets = [aws_subnet.example.id]
  vpc_config {
    subnet_ids = [aws_subnet.example.id]
  }
}

resource "aws_eks_cluster_endpoint" "example" {
  cluster_name = aws_eks_cluster.example.name
  private_access = false
  public_access = true
}