resource "aws_route53_query_log" "example" {
  name = "primary"

  cloudwatch_log_group = aws_cloudwatch_log_group.example.name

  resource_policy = data.aws_iam_policy.route53_query_logging_policy.arn
}

resource "aws_cloudwatch_log_group" "example" {
  name = "aws_route53_example_com"
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