provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "redshift_role" {
  name        = "RedshiftRole"
  description = "IAM role for Redshift"

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

resource "aws_iam_role_policy_attachment" "redshift_attach" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftServiceRolePolicyForCustomAction"
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier      = "example-cluster"
  node_type              = "dc2.large"
  cluster_type           = "single-node"
  master_username        = "admin"
  master_password        = "password123"

  iam_roles = [aws_iam_role.redshift_role.arn]
}