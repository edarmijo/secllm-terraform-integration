provider "aws" {
  region = "us-west-2"
}

data "aws_eks_cluster" "example" {
  name = "example"
}

resource "aws_iam_role_policy_attachment" "oidc_attach" {
  role       = aws_iam_role.oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "oidc_role" {
  name        = "example-oidc-role"
  description = "OIDC role for example EKS cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "example.eks.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/eks:cluster-name" : "example",
            "eks:oidc-issuer-url"               : "https://example.eks.amazonaws.com/id/example"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "oidc_oidc_policy" {
  name   = "example-oidc-policy"
  role   = aws_iam_role.oidc_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRoleWithWebIdentity",
        ]
        Effect = "Allow"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/eks:cluster-name" : "example",
            "eks:oidc-issuer-url"               : "https://example.eks.amazonaws.com/id/example"
          }
        }
      },
    ]
  })
}

resource "aws_iam_oidc_provider" "example" {
  client_id_list = ["sts.amazonaws.com"]
  url            = data.aws_eks_cluster.example.identity[0].oidc[0].issuer_url
  tags           = {
    Name = "example-oidc-provider"
  }
}