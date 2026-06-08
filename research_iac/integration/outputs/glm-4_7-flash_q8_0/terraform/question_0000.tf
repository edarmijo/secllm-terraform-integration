provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "primary."
}

resource "aws_cloudwatch_log_group" "example" {
  name = "aws_route53_example_com"
}

resource "aws_cloudwatch_log_resource_policy" "policy" {
  name = "route53-query-logging-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Route53QueryLogging"
        Effect    = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = aws_cloudwatch_log_group.example.arn
      }
    ]
  })
}

resource "aws_route53_query_logging_config" "example" {
  zone_id     = aws_route53_zone.primary.id
  log_group_arn = aws_cloudwatch_log_group.example.arn
}