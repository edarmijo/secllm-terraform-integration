provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lex_bot_role" {
  name        = "lex-bot-role"
  description = "Role for Lex Bot"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lex.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lex_bot_policy" {
  name        = "lex-bot-policy"
  description = "Policy for Lex Bot"

  policy      = jsonencode({
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

resource "aws_iam_role_policy_attachment" "lex_bot_attach" {
  role       = aws_iam_role.lex_bot_role.name
  policy_arn = aws_iam_policy.lex_bot_policy.arn
}

resource "aws_lex_bot" "pizza_bot" {
  name        = "pizza-bot"
  description = "Bot for ordering pizzas for kids"
  role_arn    = aws_iam_role.lex_bot_role.arn
  child_directed = true

  intent_schema_version = "1.0"

  intent {
    name = "OrderPizza"
    description = "Intent for ordering pizzas"
  }

  intent {
    name = "CancelOrder"
    description = "Intent for canceling order"
  }
}