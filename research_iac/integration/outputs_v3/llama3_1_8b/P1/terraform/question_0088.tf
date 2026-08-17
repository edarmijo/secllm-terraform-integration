provider "aws" {
  region = "us-west-2"
}

# Create an IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name        = "eks-cluster-1"
  description = "EKS Cluster Role"

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

# Attach the AmazonEKSClusterPolicy to the IAM role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Define the EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      "subnet-12345678",
      "subnet-90123456",
      "subnet-34567890",
      "subnet-67890123"
    ]
  }
}

# Define the cluster version
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      "subnet-12345678",
      "subnet-90123456",
      "subnet-34567890",
      "subnet-67890123"
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# Define the cluster version
variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.21"
}

# Define the cluster name
variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "my-eks-cluster"
}