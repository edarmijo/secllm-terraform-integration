provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "route53_query_logging" {
  name = "route53-query-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "route53_query_logging_policy" {
  name = "route53-query-logging-policy"
  role = aws_iam_role.route53_query_logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:log-group:/aws/route53/primary"
      },
    ]
  })
}

resource "aws_route53_zone" "primary" {
  name = "example.com"

  query_log_config {
    cloud_watch_logs_log_group_arn = aws_cloudwatch_log_group.route53_example_com.arn
  }
}

resource "aws_cloudwatch_log_group" "route53_example_com" {
  name = "/aws/route53/primary"
}