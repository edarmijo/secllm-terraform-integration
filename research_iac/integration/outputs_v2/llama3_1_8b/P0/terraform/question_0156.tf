provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lambda_exec" {
  name        = "test_lambda_exec"
  description = "Execution role for test Lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name   = "test_lambda_exec_policy"
  role   = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "test_lambda"
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_event_rule" "ec2_image_created" {
  name        = "EC2ImageCreatedRule"
  description = "Triggered when an EC2 image is created"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Image State Change"]
    detail       = "{\"state\":\"pending\"}"
  })
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.ec2_image_created.name
  target_id = "test_lambda"
  arn       = aws_lambda_function.test_lambda.arn

  input = jsonencode({
    event = {
      detail-type = ["EC2 Image State Change"]
      detail      = "{\"state\":\"pending\"}"
    }
  })
}

resource "aws_cloudwatch_event_rule" "ec2_image_created_trigger" {
  name        = "EC2ImageCreatedTriggerRule"
  description = "Triggers test Lambda function when an EC2 image is created"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Image State Change"]
    detail       = "{\"state\":\"pending\"}"
  })
}

resource "aws_cloudwatch_event_target" "lambda_trigger_test_lambda" {
  rule      = aws_cloudwatch_event_rule.ec2_image_created_trigger.name
  target_id = "test_lambda"
  arn       = aws_lambda_function.test_lambda.arn

  input = jsonencode({
    event = {
      detail-type = ["EC2 Image State Change"]
      detail      = "{\"state\":\"pending\"}"
    }
  })
}