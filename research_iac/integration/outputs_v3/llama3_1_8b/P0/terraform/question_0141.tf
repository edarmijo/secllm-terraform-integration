provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "redshift_cluster_role" {
  name        = "RedShiftClusterRole"
  description = "For RedShift Cluster"

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

resource "aws_iam_role_policy" "redshift_cluster_policy" {
  name   = "RedShiftClusterPolicy"
  role   = aws_iam_role.redshift_cluster_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "redshift:DescribeClusters",
          "redshift:DescribeClustersMessage",
          "redshift:GetClusterCredentials",
          "redshift:GetClusterParameterGroup",
          "redshift:GetClusterSnapshot",
          "redshift:GetClusterSubnetGroup",
          "redshift:GetReservedNodeExchangeStatus",
          "redshift:GetUsageLimit",
          "redshift:ListClusters",
          "redshift:RevokeClusterSecurityGroupInboundRule",
          "redshift:RevokeClusterSecurityGroupInboundRules",
          "redshift:UpdateCluster"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "redshift_endpoint_role" {
  name        = "RedShiftEndpointRole"
  description = "For RedShift Endpoint"

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

resource "aws_iam_role_policy" "redshift_endpoint_policy" {
  name   = "RedShiftEndpointPolicy"
  role   = aws_iam_role.redshift_endpoint_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "redshift:DescribeClusters",
          "redshift:GetClusterCredentials",
          "redshift:GetClusterParameterGroup",
          "redshift:GetClusterSnapshot",
          "redshift:GetClusterSubnetGroup",
          "redshift:GetReservedNodeExchangeStatus",
          "redshift:GetUsageLimit",
          "redshift:ListClusters"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "example-cluster"
  node_type         = "dc2.large"
  number_of_nodes   = 2
  database_name     = "mydb"
  master_username   = "myuser"
  master_password   = "mypassword"
}

resource "aws_redshift_cluster_endpoint" "example" {
  cluster_identifier = aws_redshift_cluster.example.cluster_identifier
  endpoint_name      = "example-endpoint"

  dynamodb_settings {
    service_role = aws_iam_role.redshift_endpoint_role.arn
  }
}