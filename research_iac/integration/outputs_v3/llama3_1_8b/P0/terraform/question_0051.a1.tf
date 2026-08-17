provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lexv2_models_bot_exec_role" {
  name        = "lexv2-models-bot-exec-role"
  description = "Execution role for Lex v2 models bot"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lexv2models-bot.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lexv2_models_bot_exec_policy" {
  name   = "lexv2-models-bot-exec-policy"
  role   = aws_iam_role.lexv2_models_bot_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_lexv2models_bot" "example" {
  name            = "example-bot"
  locale_id       = "en-US"
  role_arn        = aws_iam_role.lexv2_models_bot_exec_role.arn
}