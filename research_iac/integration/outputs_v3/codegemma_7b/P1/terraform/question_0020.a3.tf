resource "aws_route53_record" "example" {
  name = "example.com"
  type = "A"
  alias {
    name = "d-1234567890.r53.amazonaws.com"
    zone_id = "Z01234567890"
    evaluate_target_health = true
  }
  zone = "Z01234567890"
}