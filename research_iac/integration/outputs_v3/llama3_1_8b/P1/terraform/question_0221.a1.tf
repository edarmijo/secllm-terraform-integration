provider "aws" {
  region = "us-west-2"
}

data "aws_secretsmanager_secret" "dynamodb_table_credentials" {
  name = "dynamodb-table-credentials"
}

data "aws_secretsmanager_secret_version" "dynamodb_table_credentials" {
  secret_id = data.aws_secretsmanager_secret.dynamodb_table_credentials.id
}

locals {
  dynamodb_table_credentials = jsondecode(data.aws_secretsmanager_secret_version.dynamodb_table_credentials.secret_string)
}

resource "aws_iam_role" "dynamodb_table_role" {
  name        = "dynamodb-table-role"
  description = "Role for DynamoDB table"

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

resource "aws_iam_policy" "dynamodb_table_policy" {
  name        = "dynamodb-table-policy"
  description = "Policy for DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect = "Allow"
        Resource = aws_dynamodb_table.dynamodb_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_table_attach" {
  role       = aws_iam_role.dynamodb_table_role.name
  policy_arn = aws_iam_policy.dynamodb_table_policy.arn
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "dynamodb-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key       = "name"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}

resource "aws_kms_key" "dynamodb_table_key" {
  description             = "KMS key for DynamoDB table"
  deletion_window_in_days = 10
  enable_key_rotation      = true
}

resource "aws_security_group" "dynamodb_table_sg" {
  name        = "dynamodb-table-sg"
  description = "Security group for DynamoDB table"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_dynamodb_table_item" "dynamodb_table_item" {
  table_name = aws_dynamodb_table.dynamodb_table.name
  hash_key    = "id"
  range_key    = "name"

  item = jsonencode({
    id = "id-1"
    name = "name-1"
  })
}