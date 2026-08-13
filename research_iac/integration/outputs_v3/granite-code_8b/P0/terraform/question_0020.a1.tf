resource "aws_route53_record" "example" {
  zone_id = "/hostedzone/Z26RNL4JYFTOTI"
  name    = "example.com"
  type    = "A"
  alias_target {
    hosted_zone_id = "Z2DOBCW7CSO5E4"
    dns_name       = "example-elb-1234567890.us-east-1.elb.amazonaws.com"
    evaluate_target_health = true
  }
}