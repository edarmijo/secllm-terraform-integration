resource "aws_route53_zone" "primary" {
  name = "example.com."
}

resource "aws_route53_record" "us-continent" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "us.example.com."
  type    = "A"
  ttl     = 60
  records = [aws_instance.us-server.public_ip]
}

resource "aws_route53_record" "eu-continent" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "eu.example.com."
  type    = "A"
  ttl     = 60
  records = [aws_instance.eu-server.public_ip]
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example.com."
  type    = "A"
  ttl     = 60
  records = [
    aws_instance.us-server.public_ip,
    aws_instance.eu-server.public_ip,
  ]
}