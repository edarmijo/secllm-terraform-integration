provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "lex_bot_credentials" {
  name = "lex-bot-credentials"
}

data "aws_secretsmanager_secret_version" "lex_bot_credentials" {
  secret_id = data.aws_secretsmanager_secret.lex_bot_credentials.id
}

locals {
  lex_bot_name = "pizza-ordering-bot"
  lex_conclusion_statement = "Your pizza has been ordered. Please wait for confirmation from the restaurant."
}

resource "aws_lex_bot" "pizza_ordering_bot" {
  name            = local.lex_bot_name
  role_arn        = aws_iam_role.lex_bot_exec_role.arn
  locale          = "en-US"
  conversation_flow_arn = aws_lex_conversation_flow.pizza_ordering_flow.arn

  alias {
    name = "pizza-ordering-bot"
  }
}

resource "aws_lex_conversation_flow" "pizza_ordering_flow" {
  name            = local.lex_bot_name
  locale          = "en-US"

  intent {
    name        = "OrderPizzaIntent"
    description = "An intent to order a pizza"
  }

  slot_type {
    name        = "CrustType"
    description = "The type of crust for the pizza"
    enumeration_values {
      value = "Thin"
    }
    enumeration_values {
      value = "Thick"
    }
  }

  slot_type {
    name        = "Topping1"
    description = "The first topping for the pizza"
    is_required = true
  }

  slot_type {
    name        = "Topping2"
    description = "The second topping for the pizza"
    is_required = false
  }
}

resource "aws_lex_intent" "order_pizza_intent" {
  name            = "OrderPizzaIntent"
  locale          = "en-US"

  description     = "An intent to order a pizza"
  slots {
    name        = "CrustType"
    description = "The type of crust for the pizza"
  }
  slots {
    name        = "Topping1"
    description = "The first topping for the pizza"
  }
  slots {
    name        = "Topping2"
    description = "The second topping for the pizza"
  }

  reponses {
    value = local.lex_conclusion_statement
  }
}

resource "aws_iam_role" "lex_bot_exec_role" {
  name               = "${local.lex_bot_name}-exec-role"
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

resource "aws_iam_role_policy" "lex_bot_exec_policy" {
  name   = "${local.lex_bot_name}-exec-policy"
  role   = aws_iam_role.lex_bot_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lex:PutSession",
          "lex:GetSession",
          "lex:DeleteSession",
          "lex:PostText",
          "lex:PostAudioMessage",
          "lex:PostImage",
          "lex:PostVideo",
          "lex:PostSipAddress"
        ]
        Resource = aws_lex_bot.pizza_ordering_bot.arn
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lex_bot_secret_policy" {
  name   = "${local.lex_bot_name}-secret-policy"
  role   = aws_iam_role.lex_bot_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue"
        Resource = data.aws_secretsmanager_secret_version.lex_bot_credentials.arn
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_security_group" "lex_bot_sg" {
  name        = "${local.lex_bot_name}-sg"
  description = "Security group for Lex bot"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "lex_bot_sg_rule" {
  security_group_id = aws_security_group.lex_bot_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.0.1.0/24"]
}