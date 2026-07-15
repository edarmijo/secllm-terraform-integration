resource "aws_route_53_record" "non-alias" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "internal.example53.com"
  type    = "A"
  alias   = false

  set_identifier = "main"
  vpc            = aws_vpc.main.id
}