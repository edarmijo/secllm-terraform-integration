resource "aws_eks_identity_provider" "example" {
  name               = "example-oidc"
  cluster_name       = aws_eks_cluster.example.name
  oidc_provider_type = "OIDC"

  config {
    client_id     = "your-client-id"
    identity_provider_config_name = "your-identity-provider-config-name"
    issuer_url    = "https://your-issuer-url.com"
  }
}