resource "aws_route53_weighted_routing_policy" "weighted-routing" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "weighted-routing"
  health_check_id = aws_route53_health_check.db.id
  routing_policy {
    type = "weighted"
    weight_target_name = aws_route53_weighted_target.replica-1.name
    weight_target_name = aws_route53_weighted_target.replica-2.name
  }
}