provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_traffic_policy" "example" {
  name        = "example-traffic-policy"
  comment     = "Example Traffic Policy"
  document    = <<EOF
{
  "Statement": [
    {
      "Principal": "*",
      "Action": "dns:GetAuthorizationCode",
      "Effect": "Allow"
    }
  ]
}
EOF
}