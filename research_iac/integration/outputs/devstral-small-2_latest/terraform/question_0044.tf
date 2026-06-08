provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lex_bot_role" {
  name = "lex-pizza-bot-role"

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

resource "aws_iam_role_policy" "lex_bot_policy" {
  name = "lex-pizza-bot-policy"
  role = aws_iam_role.lex_bot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
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

resource "aws_lex_bot" "pizza_order_bot" {
  name        = "PizzaOrderBot"
  description = "A bot for ordering pizza with follow-up questions"
  child_directed = false
  locale = "en_US"
  process_behavior = "BUILD"

  intents {
    intent_name = aws_lex_intent.pizza_order.name
    intent_version = "$LATEST"
  }

  idle_session_ttl_in_seconds = 300
}

resource "aws_lex_intent" "pizza_order" {
  name        = "OrderPizza"
  description = "Intent for ordering pizza"

  sample_utterances = ["I want to order a pizza", "Can I get a pizza?", "Order pizza please"]

  fulfillment_activity {
    type = "ReturnIntent"
  }

  slots {
    name = "PizzaSize"
    description = "Size of the pizza"
    slot_type = "AMAZON.Standard.Pizza.Size"
    value_elicitation_prompt {
      max_attempts = 2
      messages {
        content      = "What size pizza would you like? (Small, Medium, Large)"
        content_type = "PlainText"
      }
    }
  }

  slots {
    name = "PizzaTopping"
    description = "Toppings for the pizza"
    slot_type = "AMAZON.Standard.Pizza.Topping"
    value_elicitation_prompt {
      max_attempts = 2
      messages {
        content      = "What toppings would you like?"
        content_type = "PlainText"
      }
    }
  }

  follow_up_dependency {
    parent_intent_name = aws_lex_intent.pizza_order.name
    parent_intent_version = "$LATEST"

    follow_up_intent {
      intent_name = aws_lex_intent.confirm_order.name
      intent_version = "$LATEST"
    }
  }
}

resource "aws_lex_intent" "confirm_order" {
  name        = "ConfirmOrder"
  description = "Intent for confirming the pizza order"

  sample_utterances = ["Yes, that's correct", "That sounds good", "Confirm my order"]

  fulfillment_activity {
    type = "ReturnIntent"
  }

  slots {
    name = "Confirmation"
    description = "Confirmation of the order"
    slot_type = "AMAZON.Standard.Confirmation"
    value_elicitation_prompt {
      max_attempts = 2
      messages {
        content      = "Would you like to confirm your order? (Yes/No)"
        content_type = "PlainText"
      }
    }
  }

  dialog_code_hook {
    enabled = true
    message_version = "1.0"
  }
}

resource "aws_lex_bot_alias" "pizza_order_alias" {
  bot_name       = aws_lex_bot.pizza_order_bot.name
  bot_version    = aws_lex_bot.pizza_order_bot.version
  name           = "PizzaOrderAlias"
  description    = "Alias for the pizza order bot"

  routing_configuration {
    intent {
      intent_name = aws_lex_intent.pizza_order.name
      intent_version = "$LATEST"
    }
  }
}