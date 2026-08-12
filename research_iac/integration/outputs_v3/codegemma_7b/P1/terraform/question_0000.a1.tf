resource "aws_route53_query_log" "example" {
  zone_id = aws_route53_zone.primary.zone_id

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.example.arn

  resource_policy = data.aws_iam_policy.route53_query_logging_policy.arn
}

resource "aws_cloudwatch_log_group" "example" {
  name = "aws_route53_example_com"
}

resource "aws_route53_zone" "primary" {
  name = "primary"
}

data "aws_iam_policy" "route53_query_logging_policy" {
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.example.arn}"
      ]
    }
  ]
}
POLICY
}