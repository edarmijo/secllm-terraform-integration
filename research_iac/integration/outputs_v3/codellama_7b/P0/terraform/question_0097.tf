resource "aws_eks_cluster" "example" {
  name = "example"
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99A03964B27F0E5215B1FE716097FFE0227368"]
  url = "https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE"
}

resource "aws_iam_role" "example" {
  name = "example"
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
      }
    ]
  })
}