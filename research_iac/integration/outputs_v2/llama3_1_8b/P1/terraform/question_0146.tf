# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a new IAM Role for RedShift Cluster
resource "aws_iam_role" "redshift_cluster_role" {
  name        = "${var.cluster_name}-redshift-cluster-role"
  description = "RedShift Cluster IAM Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })
}

# Create a new IAM Policy for RedShift Cluster
resource "aws_iam_policy" "redshift_cluster_policy" {
  name        = "${var.cluster_name}-redshift-cluster-policy"
  description = "RedShift Cluster IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "redshift:DescribeClusters",
          "redshift:DescribeClusterSnapshots",
          "redshift:CreateClusterSnapshot",
          "redshift:DeleteClusterSnapshot",
          "redshift:RestoreClusterFromSnapshot",
          "redshift:ModifyCluster",
          "redshift:ResizeCluster"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM Policy to the RedShift Cluster Role
resource "aws_iam_role_policy_attachment" "redshift_cluster_attach" {
  role       = aws_iam_role.redshift_cluster_role.name
  policy_arn = aws_iam_policy.redshift_cluster_policy.arn
}

# Create a new RedShift Cluster
resource "aws_redshift_cluster" "example" {
  cluster_identifier      = var.cluster_name
  node_type              = "dc2.large"
  cluster_type           = "single-node"
  master_username        = var.master_username
  master_password        = aws_secretsmanager_secret.redshift_master_password.arn
  vpc_security_group_ids = [aws_security_group.redshift_sg.id]
}

# Create a new Security Group for RedShift Cluster
resource "aws_security_group" "redshift_sg" {
  name        = "${var.cluster_name}-redshift-sg"
  description = "RedShift Cluster Security Group"

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
}

# Create a new Secrets Manager Secret for RedShift Master Password
resource "aws_secretsmanager_secret" "redshift_master_password" {
  name        = "${var.cluster_name}-redshift-master-password"
  description = "RedShift Cluster Master Password"

  # Store the secret value in AWS Secrets Manager
  secret_string = var.master_password
}

# Reference the RedShift IAM Role with the cluster
resource "aws_redshift_cluster_instance_role" "example" {
  cluster_identifier = aws_redshift_cluster.example.cluster_identifier
  role_arn           = aws_iam_role.redshift_cluster_role.arn
}