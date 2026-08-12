resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "txt_record" {
  zone_id = aws_route53_zone.example.id
  name    = "_amazonsecretpassword._tcp.example.com"
  type    = "TXT"
  records = ["passwordpassword"]
  ttl     = 60
}