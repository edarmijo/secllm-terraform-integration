resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "txt_record" {
  zone_id = aws_route53_zone.example.id
  name    = "_amazonses.example.com"
  type    = "TXT"
  records = ["\"passwordpassword\""]

  depends_on = [aws_ses_domain_identity.example]
}