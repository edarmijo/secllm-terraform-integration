provider "aws" {
  region = var.region
}

variable "cluster_name" {
  type = string
}

variable "version" {
  type = string
}

resource "aws_iam_role" "eks-cluster-1" {
  name = "eks-cluster-1"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "AmazonEKSClusterPolicy" {
  name = "AmazonEKSClusterPolicy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": "*"
    }
  ]
}
EOF
}

resource "aws_eks_cluster" "eks-cluster-1" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-cluster-1.arn
  version  = var.version

  subnet_ids = [
    "subnet-12345678",
    "subnet-87654321"
  ]

  # Add other configuration options as needed
}