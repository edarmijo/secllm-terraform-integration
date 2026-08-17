provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eks-cluster-1" {
  name = "eks-cluster-1"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks-cluster-1-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks-cluster-1.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks-cluster-1" {
  name     = "eks-cluster-1"
  role_arn = aws_iam_role.eks-cluster-1.arn
  version  = "1.14"

  subnet_ids = [
    "subnet-12345678",
    "subnet-87654321"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-1-AmazonEKSClusterPolicy
  ]
}