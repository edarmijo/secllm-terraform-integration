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
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_lex_bot" "example_bot" {
  name        = "example-bot"
  description = "Example bot with multiple slots"
  child_directed = false
  locale = "en_US"
  intents {
    intent_name = aws_lex_intent.example_intent.name
  }
}

resource "aws_lex_intent" "example_intent" {
  name        = "example-intent"
  description = "Example intent with multiple slots"

  sample_utterances = ["Hello", "Hi there"]
  fulfillment_activity {
    type = "ReturnIntent"
  }

  slot {
    name          = "slot1"
    description   = "First slot"
    slot_type     = aws_lex_slot_type.example_slot_type.name
    value_elicitation_prompt {
      max_attempts = 2
      message {
        content      = "Please provide the first value"
        content_type = "PlainText"
      }
    }
  }

  slot {
    name          = "slot2"
    description   = "Second slot"
    slot_type     = aws_lex_slot_type.example_slot_type.name
    value_elicitation_prompt {
      max_attempts = 2
      message {
        content      = "Please provide the second value"
        content_type = "PlainText"
      }
    }
  }
}

resource "aws_lex_slot_type" "example_slot_type" {
  name        = "example-slot-type"
  description = "Example slot type"

  slot_type_values {
    sample_value {
      value = "value1"
    }
  }

  slot_type_values {
    sample_value {
      value = "value2"
    }
  }
}