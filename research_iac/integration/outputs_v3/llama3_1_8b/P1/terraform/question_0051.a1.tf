provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

variable "name_prefix" {
  type = string
}

variable "name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "region" {
  type = string
}

resource "aws_iam_role" "lexv2_models_bot_exec_role" {
  name        = "${var.name_prefix}-lexv2-models-bot-exec-role"
  description = "Execution role for Lex V2 models bot"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lexv2-models-bot.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lexv2_models_bot_exec_policy" {
  name   = "${var.name_prefix}-lexv2-models-bot-exec-policy"
  role   = aws_iam_role.lexv2_models_bot_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "lexv2-models-bot:GetSession",
          "lexv2-models-bot:PostText",
        ]
        Effect   = "Allow"
        Resource = "${aws_lexv2_bot.lexv2_models_bot.arn}:*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lexv2_models_bot_exec_policy_s3" {
  name   = "${var.name_prefix}-lexv2-models-bot-exec-policy-s3"
  role   = aws_iam_role.lexv2_models_bot_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.lexv2_models_bot.arn}/*"
      },
    ]
  })
}

resource "aws_lexv2_bot" "lexv2_models_bot" {
  name            = var.name
  locale_id       = "en-US"
  description     = "Lex V2 models bot"
  idle_session_ttl_in_seconds = 300

  alias {
    name        = "${var.name_prefix}-alias"
    description = "Alias for Lex V2 models bot"
  }
}

resource "aws_lexv2_intent" "lexv2_models_bot_intent" {
  name            = var.name
  locale_id       = "en-US"
  description     = "Intent for Lex V2 models bot"

  parent_intent_signature {
    intent_name = aws_lexv2_intent.lexv2_models_bot_parent_intent.name
  }
}

resource "aws_lexv2_intent" "lexv2_models_bot_parent_intent" {
  name            = "${var.name_prefix}-parent-intent"
  locale_id       = "en-US"
  description     = "Parent intent for Lex V2 models bot"

  parent_intent_signature {
    intent_name = aws_lexv2_intent.lexv2_models_bot_parent_intent.name
  }
}

resource "aws_s3_bucket" "lexv2_models_bot" {
  bucket = var.bucket_name

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "lexv2_models_bot_policy" {
  bucket = aws_s3_bucket.lexv2_models_bot.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.lexv2_models_bot.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lexv2_models_bot_exec_attach" {
  role       = aws_iam_role.lexv2_models_bot_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLexV2ModelExecutionRolePolicy"
}