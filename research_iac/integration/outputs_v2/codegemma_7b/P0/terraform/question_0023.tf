provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_record" "example" {
  name = "_domain-verification.example."
  type = "TXT"
  ttl = 3600
  resource_records = ["passwordpassword"]
}