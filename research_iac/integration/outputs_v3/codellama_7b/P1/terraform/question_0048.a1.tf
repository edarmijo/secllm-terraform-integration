provider "aws" {
  region = "us-east-1"
}

resource "aws_lex_bot" "pizza_ordering_for_kids" {
  name        = "PizzaOrderingForKids"
  description = "A Lex bot for ordering pizzas for kids"
  role        = aws_iam_role.lex_bot_role.arn
  child_directed = true
  intents     = [
    {
      name        = "OrderPizza"
      description = "Intent for ordering a pizza"
      slots       = [
        {
          name        = "PizzaSize"
          description = "Slot for pizza size"
          type        = "AMAZON.Size"
          values      = ["Small", "Medium", "Large"]
        },
        {
          name        = "PizzaToppings"
          description = "Slot for pizza toppings"
          type        = "AMAZON.List"
          values      = ["Pepperoni", "Mushrooms", "Onions", "Green Peppers"]
        }
      ]
    }
  ]
  abort_statement {
    messages = [
      {
        content = "I'm not able to help with that. Let me try to assist you with something else."
        content_type = "PlainText"
      }
    ]
  }
  fulfillment_activity {
    type = "CodeHook"
    code_hook {
      uri = "arn:aws:lambda:us-east-1:123456789012:function:PizzaOrderingForKids"
    }
  }
}

resource "aws_iam_role" "lex_bot_role" {
  name               = "LexBotRole"
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
  name        = "LexBotPolicy"
  description = "Policy for Lex bot"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lex:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lex_bot_policy_attachment" {
  role       = aws_iam_role.lex_bot_role.name
  policy_arn = aws_iam_policy.lex_bot_policy.arn
}