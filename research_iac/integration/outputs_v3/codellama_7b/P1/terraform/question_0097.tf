provider "aws" {
  region = "us-east-1"
}

resource "aws_eks_cluster" "example" {
  name = "example"

  # OIDC configuration
  identity {
    oidc {
      client_id     = "your-client-id"
      identity_provider_config {
        name = "your-identity-provider-config-name"
        issuer_url = "https://your-issuer-url.com"
      }
    }
  }
}