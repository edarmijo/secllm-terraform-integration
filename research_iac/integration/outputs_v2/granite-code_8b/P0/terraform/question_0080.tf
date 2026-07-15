resource "aws_route53_zone" "private_zone" {
  name = "internal.example53.com"
}

resource "aws_route53_record" "non_alias_record" {
  zone_id = aws_route53_zone.private_zone.id
  name    = "example.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_vpc.main.id
    evaluate_target_health = false
    dns_name         = aws_elb.my_elb.dns_name
  }
}