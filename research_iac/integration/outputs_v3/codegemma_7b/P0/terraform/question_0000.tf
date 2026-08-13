provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "primary.com"
}

resource "aws_cloudwatch_log_group" "aws_route53_example_com" {
  name = "/aws/route53/example.com"
}

resource "aws_cloudwatch_log_resource_policy" "route53-query-logging-policy" {
  name = "route53-query-logging-policy"
  policy_document = <<POLICY_DOCUMENT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.aws_route53_example_com.arn}"
      ]
    }
  ]
}
POLICY_DOCUMENT
}

resource "aws_route53_query_logging_config" "example" {
  zone_id = aws_route53_zone.primary.zone_id
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.aws_route53_example_com.arn
  resource_policy_arn = aws_cloudwatch_log_resource_policy.route53-query-logging-policy.arn
}