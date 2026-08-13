resource "aws_route53_zone" "primary" {
  name = "primary.example.com"
}

resource "aws_cloudwatch_log_group" "aws_route53_example_com" {
  name = "aws_route53_example_com"
}

resource "aws_cloudwatch_log_resource_policy" "route53-query-logging-policy" {
  policy_name     = "route53-query-logging-policy"
  log_group_arn   = aws_cloudwatch_log_group.aws_route53_example_com.arn
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "logs:PutLogEvents"
        Effect   = "Allow"
        Resource = aws_cloudwatch_log_group.aws_route53_example_com.arn
      }
    ]
  })
}