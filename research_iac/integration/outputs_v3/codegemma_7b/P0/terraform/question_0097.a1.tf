provider "aws" {
  region = "us-east-1"
}

resource "aws_eks_cluster" "example" {
  name = "example"
  role_arn = "example_role_arn"
  vpc_config {
    security_group_ids = ["example_security_group_id"]
    subnets = ["example_subnet_id"]
  }
}

resource "aws_iam_openid_connect_provider" "example" {
  client_id_list = ["example_client_id"]
  thumbprint_list = ["example_thumbprint"]
  url = "example_issuer_url"
}

resource "aws_eks_cluster_oidc_identity_provider" "example" {
  cluster_name = aws_eks_cluster.example.name
  identity_provider_name = aws_iam_openid_connect_provider.example.name
}