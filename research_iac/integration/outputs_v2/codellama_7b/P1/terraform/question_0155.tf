provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "example" {
  filename      = "lambda.zip"
  function_name = "example"
  role          = aws_iam_role.example.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"
}

resource "aws_cloudwatch_event_rule" "example" {
  name                = "example-schedule"
  description         = "Triggers the Lambda function every 15 minutes"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "example" {
  rule      = aws_cloudwatch_event_rule.example.name
  target_id = "example"
  arn       = aws_lambda_function.example.arn
}

resource "aws_iam_role" "example" {
  name               = "example-lambda-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}