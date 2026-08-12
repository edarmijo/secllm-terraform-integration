provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "dynamodb_table_password" {
  name = "DynamoDBTablePassword"
}

resource "aws_iam_role" "dynamodb_table_exec_role" {
  name               = "${var.application_name}-dynamodb-table-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb_table_exec_policy" {
  name   = "${var.application_name}-dynamodb-table-exec-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.dynamodb_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_table_exec_attach" {
  role       = aws_iam_role.dynamodb_table_exec_role.name
  policy_arn = aws_iam_policy.dynamodb_table_exec_policy.arn
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = var.application_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "name"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_master_key_id = aws_kms_key.dynamodb_table_key.arn
  }
}

resource "aws_kms_key" "dynamodb_table_key" {
  description             = "${var.application_name} DynamoDB Table Key"
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Action    = "kms:*"
        Resource  = "*"
        Principal = {
          Service = "iam.amazonaws.com"
        }
      },
      {
        Sid       = "Allow DynamoDB to use the key"
        Effect    = "Allow"
        Action    = "kms:Encrypt",
        Action    = "kms:ReEncrypt",
        Action    = "kms:GenerateDataKey*"
        Resource  = aws_kms_key.dynamodb_table_key.arn
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
      },
    ]
  })
}