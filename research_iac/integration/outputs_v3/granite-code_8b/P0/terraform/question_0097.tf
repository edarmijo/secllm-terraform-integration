resource "aws_eks_cluster" "example" {
  name = "example"

  # other configuration options...
}

resource "aws_eks_identity_provider_config" "example" {
  cluster_name            = aws_eks_cluster.example.name
  identity_provider_type  = "OIDC"
  oidc_client_id_list     = ["your-client-id"]
  oidc_identity_provider = "https://your-oidc-provider.com"

  # other configuration options...
}