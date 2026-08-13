provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "dynamodb_exec_role" {
  name        = "DynamoDBExecRole"
  description = "Execution role for DynamoDB"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "dynamodb_exec_policy" {
  name        = "DynamoDBExecPolicy"
  description = "Execution policy for DynamoDB"

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
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_exec_attach" {
  role       = aws_iam_role.dynamodb_exec_role.name
  policy_arn = aws_iam_policy.dynamodb_exec_policy.arn
}

resource "aws_dynamodb_table" "example_table" {
  name           = "ExampleTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
    kms_master_key_id = aws_kms_key.example_key.arn
  }
}

resource "aws_kms_key" "example_key" {
  description             = "Example KMS key for DynamoDB encryption"
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow DynamoDB to use the key"
        Effect    = "Allow"
        Action    = ["kms:Encrypt", "kms:Decrypt"]
        Resource  = "*"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
      },
    ]
  })
}