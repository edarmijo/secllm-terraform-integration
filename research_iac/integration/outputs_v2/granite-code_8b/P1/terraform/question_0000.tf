provider "aws" {
  region = var.region
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}

resource "aws_cloudwatch_log_group" "aws_route53_example_com" {
  name              = "aws_route53_example_com"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_resource_policy" "route53-query-logging-policy" {
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [
          "${aws_cloudwatch_log_group.aws_route53_example_com.arn}:log-stream:*",
          "${aws_cloudwatch_log_group.aws_route53_example_com.arn}:log-events:*"
        ]
      }
    ]
  })
}