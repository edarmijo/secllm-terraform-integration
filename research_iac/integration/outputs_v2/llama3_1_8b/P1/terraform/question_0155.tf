provider "aws" {
  region = var.region
}

data "aws_secretsmanager_secret_version" "lambda_execution_role" {
  secret_id = var.lambda_execution_role_arn
}

locals {
  lambda_execution_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowExecutionRoleToAssumeLambdaExecutionRole"
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Resource  = var.lambda_execution_role_arn
      },
      {
        Sid       = "AllowLambdaExecutionRoleToInvokeCloudWatchEvents"
        Effect    = "Allow"
        Action    = "events:*"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = var.lambda_function_name
  assume_role_policy = local.lambda_execution_role_policy
}

resource "aws_iam_role_policy" "lambda_execution_role_policy" {
  role   = aws_iam_role.lambda_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowLambdaExecutionRoleToInvokeCloudWatchEvents"
        Effect    = "Allow"
        Action    = "events:*"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "lambda_function" {
  filename      = var.lambda_function_filename
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  role          = aws_iam_role.lambda_execution_role.arn

  vpc_config {
    subnet_ids         = [var.subnet_id]
    security_group_ids = [var.security_group_id]
  }
}

resource "aws_cloudwatch_event_rule" "lambda_invocation_rule" {
  name                = var.lambda_function_name
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_invocation_target" {
  rule      = aws_cloudwatch_event_rule.lambda_invocation_rule.name
  target_id = "${var.lambda_function_name}-target"
  arn       = aws_lambda_function.lambda_function.arn

  input_transformer {
    input_paths = {
      "Payload" = "$$.Payload"
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role_attach" {
  role       = aws_iam_role.lambda_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}