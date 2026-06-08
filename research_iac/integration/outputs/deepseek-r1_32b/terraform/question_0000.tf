provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "route53_logging_role" {
  name = "route53-query-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "route53.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "route53_logging_policy" {
  name   = "route53-query-logging-policy"
  role   = aws_iam_role.route53_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "route53_logs" {
  name              = "aws_route53_example_com"
  retention_in_days = 0
}

resource "aws_cloudwatch_log_resource_policy" "route53_logging_policy" {
  policy_name = "route53-query-logging-policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = "*"
      Action = [
        "logs:PutLogEvents",
        "logs:CreateLogStream"
      ]
      Resource = "${aws_cloudwatch_log_group.route53_logs.arn}:*"
    }]
  })
}

resource "aws_route53_zone" "primary" {
  name = "example.com."
}

resource "aws_route53_query_logging_config" "logging" {
  zone_id         = aws_route53_zone.primary.id
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_logs.arn
  iam_role_arn    = aws_iam_role.route53_logging_role.arn
}