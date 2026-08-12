provider "aws" {
  region = var.region
}

resource "aws_iam_role" "example-eks-cluster-role" {
  name               = "example-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.example-eks-cluster-assume-role-policy.json
}

data "aws_iam_policy_document" "example-eks-cluster-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "example-eks-cluster-role-attach-amazon-eks-cluster-policy" {
  role       = aws_iam_role.example-eks-cluster-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "example-eks-cluster" {
  name     = "example-eks-cluster"
  role_arn = aws_iam_role.example-eks-cluster-role.arn

  subnet_ids = [
    aws_subnet.example-eks-cluster-subnet.id,
  ]

  depends_on = [
    aws_iam_role_policy_attachment.example-eks-cluster-role-attach-amazon-eks-cluster-policy,
  ]

  endpoint_private_access = false
  endpoint_public_access  = true
}

resource "aws_subnet" "example-eks-cluster-subnet" {
  cidr_block           = var.cidr_block
  availability_zone     = var.availability_zone
  availability_zone_id = var.availability_zone_id
  vpc_id                = aws_vpc.example-eks-cluster-vpc.id

  tags = {
    Name = "example-eks-cluster-subnet"
  }
}

resource "aws_vpc" "example-eks-cluster-vpc" {
  cidr_block           = var.cidr_block
  availability_zone     = var.availability_zone
  availability_zone_id = var.availability_zone_id

  tags = {
    Name = "example-eks-cluster-vpc"
  }
}