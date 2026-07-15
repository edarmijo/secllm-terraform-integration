provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

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
        Resource = "${aws_cloudwatch_log_group.query_log.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "query_log" {
  name              = "aws_route53_example_com"
  retention_in_days = 30
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
        Resource = aws_cloudwatch_log_group.query_log.arn
      }
    ]
  })
}

resource "aws_route53_query_log_config" "query_log_config" {
  name           = "primary"
  cloudwatch_logs_log_group_arn = aws_cloudwatch_log_group.query_log.arn
}