provider "aws" {
  region = var.region
}

resource "aws_iam_role" "eks_cluster_1" {
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

resource "aws_iam_role_policy_attachment" "eks_cluster_1_policy" {
  role       = aws_iam_role.eks_cluster_1.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks_cluster_1" {
  name                = var.cluster_name
  version             = var.cluster_version
  role_arn            = aws_iam_role.eks_cluster_1.arn
  vpc_config {
    subnet_ids = var.subnet_ids
  }
}