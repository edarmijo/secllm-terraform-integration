provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_traffic_policy" "example" {
  name         = "example-traffic-policy"
  comment      = "Example traffic policy"
  document     = <<EOF
{
  "Version": "2017-11-28",
  "Statement": [
    {
      "Name": "example-statement",
      "Action": "dns:GetHostedZone",
      "Effect": "Allow",
      "Resource": "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
    }
  ]
}
EOF
}

variable "hosted_zone_id" {
  type = string
}