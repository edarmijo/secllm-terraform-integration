provider "aws" {
  region = "us-west-2"
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

resource "aws_iam_role" "eks-cluster-1" {
  name = "eks-cluster-1"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "eks-cluster-1-policy" {
  name       = "eks-cluster-1-policy"
  roles      = [aws_iam_role.eks-cluster-1.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks-cluster-1" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks-cluster-1.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }
}