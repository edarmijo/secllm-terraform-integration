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

  alias = "KidsPizzaAlias"

  idle_session_ttl_in_seconds = 300

  conversation_flow_arn = aws_lex_bot_conversation_flow.kids_pizza_flow.arn

  role_arn = aws_iam_role.lex_bot_role.arn
}

resource "aws_lex_bot_conversation_flow" "kids_pizza_flow" {
  name = "KidsPizzaFlow"
  locale = "en-US"
  parent_flow_arn = aws_lex_bot.kids_pizza_bot.arn
  conversation_flow_intents = [
    {
      name = "OrderPizza"
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
  ]
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