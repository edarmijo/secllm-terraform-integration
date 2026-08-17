provider "aws" {
  region = "us-west-2"
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/your-execution-role"
  }
}

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "lambda_secret" {
  name = "lambda-execution-role"
}

data "aws_secretsmanager_secret_version" "lambda_secret_version" {
  secret_id = data.aws_secretsmanager_secret.lambda_secret.id
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.test_lambda.arn]
  }
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    actions = ["ec2:CreateImage"]
    resources = ["*"]
  }
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.test_lambda.arn]
    condition {
      test = "StringEquals"
      values = [aws_lambda_function.test_lambda.arn]
      variable = "lambda:FunctionArn"
    }
  }
}

resource "aws_lambda_function" "test_lambda" {
  filename = "lambda_function_payload.zip"
  function_name = "test_lambda"
  handler = "index.handler"
  role = aws_iam_role.lambda_exec.arn
  runtime = "nodejs14.x"
}

resource "aws_iam_role" "lambda_exec" {
  name = "test_lambda_exec"
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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "test_lambda_policy"
  role = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "test_ec2_policy"
  role = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.ec2_policy.json
}

resource "aws_cloudwatch_event_rule" "ec2_image_created" {
  name = "ec2-image-created"
  event_pattern = jsonencode({
    source = ["aws.ec2"]
    detail-type = ["EC2 Image State Change"]
    detail = {
      state = ["pending"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule = aws_cloudwatch_event_rule.ec2_image_created.name
  target_id = "lambda-trigger"
  arn = aws_lambda_function.test_lambda.arn
  input = jsonencode({
    "version" = "0"
    "id" = "test-lambda"
    "detail-type" = ["EC2 Image State Change"]
    "detail" = {
      "state" = ["pending"]
    }
  })
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.ec2_image_created.arn
}