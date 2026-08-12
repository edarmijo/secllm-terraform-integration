provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lexbot_exec_role" {
  name        = "lexbot-exec-role"
  description = "Execution role for Lex bot"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lexbot_exec_policy" {
  name   = "lexbot-exec-policy"
  role   = aws_iam_role.lexbot_exec_role.id
  policy = jsonencode({
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
      },
      {
        Action = [
          "lambda:GetFunctionConfiguration",
          "lambda:InvokeFunction",
        ]
        Effect = "Allow"
        Resource = aws_lambda_function.pizza_bot.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lexbot_tracing_policy" {
  name   = "lexbot-tracing-policy"
  role   = aws_iam_role.lexbot_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "pizza_bot" {
  filename      = "lambda_function_payload.zip"
  function_name = "pizza-bot"
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  role = aws_iam_role.lexbot_exec_role.arn
}

resource "aws_lex_runtime_v2_bot" "pizza_bot" {
  name        = "pizza-bot"
  locale      = "en-US"
  description = "Order a pizza with Alexa"

  conversation_flow {
    name = "pizza-flow"
    flow_file_s3_bucket = "my-bucket"
    flow_file_s3_key    = "pizza.flow"
  }

  alias = aws_lex_runtime_v2_bot_alias.pizza_bot.id
}

resource "aws_lex_runtime_v2_bot_alias" "pizza_bot" {
  name        = "pizza-bot-alias"
  bot_name    = aws_lex_runtime_v2_bot.pizza_bot.name
  locale      = aws_lex_runtime_v2_bot.pizza_bot.locale
  description = "Alias for pizza bot"

  conversation_flow {
    name = "pizza-flow"
    flow_file_s3_bucket = "my-bucket"
    flow_file_s3_key    = "pizza.flow"
  }
}

resource "aws_lex_runtime_v2_intent" "order_pizza" {
  name        = "OrderPizzaIntent"
  locale      = aws_lex_runtime_v2_bot.pizza_bot.locale
  description = "Intent for ordering a pizza"

  slots = [
    {
      name         = "Crust"
      type         = "CrustType"
      description  = "The crust of the pizza"
      priority     = 1
      values       = ["Thin", "Thick"]
      values        = ["Hand-Tossed"]
    },
    {
      name         = "Toppings"
      type         = "ToppingList"
      description  = "The toppings of the pizza"
      priority     = 2
      values       = ["Pepperoni", "Sausage", "Mushrooms"]
    }
  ]

  sample_utterances = [
    {
      utterance = "I'd like to order a {Crust} crust pizza with {Toppings}."
    },
    {
      utterance = "Can I get a {Crust} crust pizza with {Toppings}?"
    }
  ]
}

resource "aws_lex_runtime_v2_intent" "conclusion" {
  name        = "ConclusionIntent"
  locale      = aws_lex_runtime_v2_bot.pizza_bot.locale
  description = "Intent for concluding the conversation"

  slots = [
    {
      name         = "Confirmation"
      type         = "Confirmation"
      description  = "The confirmation of the order"
      priority     = 1
      values       = ["Yes", "No"]
    }
  ]

  sample_utterances = [
    {
      utterance = "Thank you for ordering a {Crust} crust pizza with {Toppings}. Your total comes out to be ${Total}. Would you like to confirm your order?"
    },
    {
      utterance = "Your order has been placed successfully. Thank you for choosing our restaurant!"
    }
  ]
}