provider "aws" {
  region = var.region
}

resource "aws_iam_role" "eks-cluster-1" {
  name = "eks-cluster-1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "eks-cluster-1" {
  name = "eks-cluster-1"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  roles = [aws_iam_role.eks-cluster-1.name]
}

resource "aws_eks_cluster" "eks-cluster-1" {
  name = var.cluster_name
  version = var.cluster_version
  role_arn = aws_iam_role.eks-cluster-1.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private.id,
      aws_subnet.public.id
    ]
  }
}

resource "aws_subnet" "private" {
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.eks-vpc.id
}

resource "aws_subnet" "public" {
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.eks-vpc.id
}

resource "aws_vpc" "eks-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "eks-vpc"
  }
}