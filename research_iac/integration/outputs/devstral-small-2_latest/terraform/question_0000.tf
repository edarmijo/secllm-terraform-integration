provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "route53_query_logs" {
  name              = "aws_route53_example_com"
  retention_in_days = 7
}

resource "aws_iam_role" "route53_query_logging_role" {
  name               = "Route53QueryLoggingRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "route53.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "route53_query_logging_policy" {
  name   = "Route53QueryLoggingPolicy"
  role   = aws_iam_role.route53_query_logging_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "${aws_cloudwatch_log_group.route53_query_logs.arn}:*"
      }
    ]
  })
}

resource "aws_route53_query_log" "example" {
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
  zone_id                  = aws_route53_zone.primary.zone_id
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}