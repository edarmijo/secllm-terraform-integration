provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {
  skip_credentials_validation = true
}

data "aws_secretsmanager_secret" "lambda_layer_secret" {
  name = "lambda-layer-secret"
}

data "aws_secretsmanager_secret_version" "lambda_layer_secret_version" {
  secret_id = data.aws_secretsmanager_secret.lambda_layer_secret.id
}

data "archive_file" "lambda_layer_payload" {
  type        = "zip"
  source_file = "lambda_layer_payload.zip"
  output_path = "lambda_layer_payload.zip"
}

resource "aws_lambda_layer_version" "example" {
  filename      = data.archive_file.lambda_layer_payload.output_path
  layer_name    = "example-layer"
  compatible_runtimes = ["nodejs14.x"]
  source_code_hash = data.archive_file.lambda_layer_payload.output_base64sha256
}

resource "aws_iam_role" "lambda_layer_exec_role" {
  name        = "lambda-layer-exec-role"
  description = "Execution role for Lambda Layer"

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

resource "aws_iam_role_policy" "lambda_layer_exec_policy" {
  name   = "lambda-layer-exec-policy"
  role   = aws_iam_role.lambda_layer_exec_role.id

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
        Resource = "arn:aws:logs:*:*:*"
      },
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

resource "aws_iam_role_policy_attachment" "lambda_layer_exec_attach" {
  role       = aws_iam_role.lambda_layer_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}