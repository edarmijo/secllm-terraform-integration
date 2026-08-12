provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lex_bot_role" {
  name               = "lex_bot_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lex.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lex_bot_policy" {
  name        = "lex_bot_policy"
  description = "Policy for Lex bot"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lex:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:lex:us-east-1:${var.account_id}:bot:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lex_bot_policy_attachment" {
  role       = aws_iam_role.lex_bot_role.name
  policy_arn = aws_iam_policy.lex_bot_policy.arn
}

resource "aws_lex_bot" "pizza_ordering_bot" {
  name            = "PizzaOrderingBot"
  role_arn        = aws_iam_role.lex_bot_role.arn
  idle_session_ttl_in_seconds = 300
  clarification_prompt {
    max_attempts = 2
    message {
      content_type = "PlainText"
      text         = "Sorry, I didn't understand. Can you please provide more information?"
    }
  }
  abort_statement {
    messages {
      content_type = "PlainText"
      text         = "I'm not able to assist you with that. Goodbye!"
    }
  }
  intent_confidence_threshold = 0.5
  fulfillment_activity {
    type = "ReturnIntent"
  }
  sample_utterances = [
    "What pizza toppings do you have?",
    "I'd like to order a pepperoni pizza.",
    "Can I get a large cheese pizza with extra sauce?"
  ]
}