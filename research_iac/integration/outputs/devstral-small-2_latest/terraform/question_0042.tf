provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lex_bot_role" {
  name = "lex-bot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lex.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lex_bot_policy" {
  name = "lex-bot-policy"
  role = aws_iam_role.lex_bot_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lex_bot" "example" {
  name        = "example-bot"
  description = "Example Lex bot"
  child_directed = false

  locale {
    locale_name = "en_US"
    nlu_intent_confidence_threshold = 0.4
  }

  intents {
    intent_name = "GreetingIntent"
    intent_version = "$LATEST"

    sample_utterances = ["Hello", "Hi", "Hey"]
  }
}