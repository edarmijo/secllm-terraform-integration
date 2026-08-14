provider "aws" {
  region = "us-east-1"
}

resource "aws_eks_cluster" "example" {
  name = "example"
}

resource "aws_iam_openid_connect_provider" "example" {
  client_id_list = ["example_client_id"]
  name = "example_identity_provider"
  issuer = "example_issuer_url"
}

resource "aws_eks_cluster_oidc_identity_provider" "example" {
  cluster_name = aws_eks_cluster.example.name
  identity_provider_name = aws_iam_openid_connect_provider.example.name
}