provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lambda_exec" {
  name        = "lambda-exec-role"
  description = "Execution role for lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name   = "lambda-exec-policy"
  role   = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_invoke_policy" {
  name   = "lambda-invoke-policy"
  role   = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_lambda_function" "example" {
  filename      = "lambda_function_payload.zip"
  function_name = "example-lambda-function"
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_event_rule" "schedule_rule" {
  name                = "schedule-rule"
  schedule_expression = "cron(0/15 * * * *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule_rule.name
  target_id = "lambda-target-id"
  arn       = aws_lambda_function.example.arn

  input = jsonencode({
    message = "Invoked by CloudWatch Event"
  })
}

resource "aws_cloudwatch_event_source" "event_source" {
  event_bus_name = "default"

  depends_on = [
    aws_lambda_function.example,
  ]
}