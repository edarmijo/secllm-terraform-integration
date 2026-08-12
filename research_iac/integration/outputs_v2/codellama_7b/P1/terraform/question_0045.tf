provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_bot" "pizza_ordering_bot" {
  name        = "PizzaOrderingBot"
  description = "A bot for ordering pizzas"
  role        = aws_iam_role.pizza_ordering_bot_role.arn
  intents     = [aws_lex_intent.pizza_ordering_intent.arn]
}

resource "aws_iam_role" "pizza_ordering_bot_role" {
  name        = "PizzaOrderingBotRole"
  description = "A role for the PizzaOrderingBot"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lex.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_lex_intent" "pizza_ordering_intent" {
  name        = "PizzaOrderingIntent"
  description = "An intent for ordering pizzas"
  fulfillment_activity = jsonencode({
    Type = "ReturnIntent"
    ReturnValue = {
      AllSlots = true
      IntentName = "PizzaOrderingIntent"
    }
  })
}