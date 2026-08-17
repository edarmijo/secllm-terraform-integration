provider "aws" {
  region = "us-west-2"
}

data "aws_secretsmanager_secret" "lex_bot_secret" {
  name = "lex-bot-secret"
}

data "aws_secretsmanager_secret_version" "lex_bot_secret_version" {
  secret_id = data.aws_secretsmanager_secret.lex_bot_secret.id
}

resource "aws_secretsmanager_secret" "lex_bot_secret" {
  name        = "lex-bot-secret"
  description = "Secrets for Lex Bot"
}

resource "aws_secretsmanager_secret_version" "lex_bot_secret_version" {
  secret_id     = aws_secretsmanager_secret.lex_bot_secret.id
  secret_string = jsonencode({
    botName = "KidsPizzaBot"
    api_key = "YOUR_API_KEY"
  })
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

resource "aws_iam_role_policy" "lex_bot_policy" {
  name   = "lex-bot-policy"
  role   = aws_iam_role.lex_bot_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lex:PutBot",
          "lex:PutIntent",
          "lex:PutSlotType",
          "lex:PutUtteranceSpecification",
          "lex:CreateBotAlias",
          "lex:CreateBot",
          "lex:CreateIntent",
          "lex:CreateSlotType",
          "lex:CreateUtteranceSpecification",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lex_bot_attach" {
  role       = aws_iam_role.lex_bot_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLexFullAccess"
}

resource "aws_lex_bot" "kids_pizza_bot" {
  name         = "KidsPizzaBot"
  description  = "Bot for ordering pizzas for kids"
  child_directed = true
  intent_schema = <<EOF
{
  "version": "1.0",
  "intents": [
    {
      "name": "OrderPizza",
      "slots": [
        {
          "name": "Crust",
          "type": "CrustType"
        },
        {
          "name": "Sauce",
          "type": "SauceType"
        },
        {
          "name": "Cheese",
          "type": "CheeseType"
        }
      ]
    }
  ]
}
EOF

  idle_session_ttl_in_seconds = 300
}

resource "aws_lex_intent" "order_pizza_intent" {
  name = "OrderPizza"
  parent = aws_lex_bot.kids_pizza_bot.id
  slots = [
    {
      name = "Crust"
      type = "CrustType"
    },
    {
      name = "Sauce"
      type = "SauceType"
    },
    {
      name = "Cheese"
      type = "CheeseType"
    }
  ]
}

resource "aws_lex_slot_type" "crust_slot_type" {
  name = "CrustType"
  type = "LIST"
  values = ["ThinCrust", "ThickCrust", "GlutenFree"]
}

resource "aws_lex_slot_type" "sauce_slot_type" {
  name = "SauceType"
  type = "LIST"
  values = ["Marinara", "Alfredo", "BBQ"]
}

resource "aws_lex_slot_type" "cheese_slot_type" {
  name = "CheeseType"
  type = "LIST"
  values = ["Mozzarella", "Cheddar", "Parmesan"]
}

resource "aws_security_group" "lex_bot_sg" {
  name        = "lex-bot-sg"
  description = "Security group for Lex Bot"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}