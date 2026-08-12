provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "query_log_role" {
  name        = "route53_query_log_role"
  description = "Role for Route 53 query logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "query_log_policy" {
  name   = "route53_query_log_policy"
  role   = aws_iam_role.query_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = aws_cloudwatch_log_group.route53_example_com.arn
      }
    ]
  })
}

resource "aws_route53_zone" "primary" {
  name = "example.com."
}

resource "aws_cloudwatch_log_group" "route53_example_com" {
  name              = "aws_route53_example_com"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
  policy_name        = "route53-query-logging-policy"
  policy_document    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
        Action = "logs:PutLogEvents"
        Resource = aws_cloudwatch_log_group.route53_example_com.arn
      }
    ]
  })
}

resource "aws_route53_recursion_denied_rule" "example" {
  name           = "example"
  cloudwatch_logs_log_group_arn = aws_cloudwatch_log_group.route53_example_com.arn
}