provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}

resource "aws_cloudwatch_log_group" "aws_route53_example_com" {
  name = "aws_route53_example_com"
}

resource "aws_iam_role" "route53-query-logging-policy" {
  name = "route53-query-logging-policy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "logs.us-east-1.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "route53-query-logging-policy" {
  name = "route53-query-logging-policy"
  role = aws_iam_role.route53-query-logging-policy.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_route53_query_log" "example" {
  zone_id = aws_route53_zone.primary.id

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.aws_route53_example_com.arn
}