provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

variable "lambda_function_name" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "aws_region" {
  type = string
}

resource "aws_iam_role" "lambda_exec" {
  name        = "${var.lambda_function_name}-exec-role"
  description = "Execution role for ${var.lambda_function_name}"

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
  name   = "${var.lambda_function_name}-exec-policy"
  role   = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
          "logs:PutMetricFilter",
          "logs:GetLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "dynamodb_exec_policy" {
  name   = "${var.lambda_function_name}-dynamodb-exec-policy"
  role   = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
        ]
        Effect = "Allow"
        Resource = var.dynamodb_table_arn
      },
    ]
  })
}

resource "aws_lambda_function" "lambda_function" {
  filename      = "${path.module}/lambda_function_payload.zip"
  function_name = var.lambda_function_name
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  role = aws_iam_role.lambda_exec.arn

  depends_on = [aws_iam_role_policy.lambda_exec_policy, aws_iam_role_policy.dynamodb_exec_policy]
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity_units = 5
  write_capacity_units = 5

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_lambda_event_source_mapping" "lambda_event_source_mapping" {
  event_source_arn       = aws_dynamodb_table.dynamodb_table.stream_arn
  function_name         = aws_lambda_function.lambda_function.arn
  enabled               = true

  depends_on = [aws_lambda_function.lambda_function, aws_dynamodb_table.dynamodb_table]
}