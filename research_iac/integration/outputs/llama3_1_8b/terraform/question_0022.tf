provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "reverse_zone" {
  name = "host.example53.com."
}

resource "aws_route53_record" "pointer_record" {
  zone_id = aws_route53_zone.reverse_zone.zone_id
  name    = "0.168.192.in-addr.arpa."
  type    = "PTR"
  ttl     = "300"
  records = ["host.example53.com."]
}

output "reverse_zone_name" {
  value = aws_route53_zone.reverse_zone.name
}