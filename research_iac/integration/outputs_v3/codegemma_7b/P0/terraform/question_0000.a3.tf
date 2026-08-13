resource "aws_route53_query_logging_config" "example" {
  zone_id = aws_route53_zone.primary.zone_id
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.aws_route53_example_com.arn
  resource_policy_arn = aws_cloudwatch_log_resource_policy.route53_query_logging_policy.arn
}