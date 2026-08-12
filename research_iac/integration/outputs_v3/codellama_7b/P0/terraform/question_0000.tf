provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example.com."
}

resource "aws_cloudwatch_log_group" "aws_route53_example_com" {
  name = "/aws/route53/example.com"
}

resource "aws_cloudwatch_log_resource_policy" "route53-query-logging-policy" {
  policy_name     = "route53-query-logging-policy"
  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "route53.amazonaws.com"
      },
      "Action": "logs:PutLogEvents",
      "Resource": "${aws_cloudwatch_log_group.aws_route53_example_com.arn}"
    }
  ]
}
EOF
}