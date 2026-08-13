provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_exec" {
  name        = "${var.project_name}-lambda-exec-role"
  description = "Execution role for ${var.project_name} Lambda function"

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
  name   = "${var.project_name}-lambda-exec-policy"
  role   = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
          "logs:PutMetric",
          "logs:GetLogEvents",
          "logs:GetLogRecords",
          "logs:GetLogRecordHistory",
          "logs:GetQueryResults"
        ]
        Resource = "*"
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "dynamodb_exec_policy" {
  name   = "${var.project_name}-dynamodb-exec-policy"
  role   = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.example.arn
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_lambda_function" "example" {
  filename      = "${path.module}/lambda.zip"
  function_name = "${var.project_name}-lambda-function"
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_dynamodb_table" "example" {
  name           = "${var.project_name}-table"
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity_units = 1
  write_capacity_units = 1

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn       = aws_dynamodb_table.example.stream_arn
  function_name          = aws_lambda_function.example.arn
  enabled                = true
}