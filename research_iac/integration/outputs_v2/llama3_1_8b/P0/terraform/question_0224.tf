provider "aws" {
  region = "us-east-1"
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
      }
    ]
  })
}

resource "aws_iam_role_policy" "dynamodb_exec_policy" {
  name   = "DynamoDBExecPolicy"
  role   = aws_iam_role.dynamodb_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem",
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_dynamodb_table" "example_table" {
  name           = "ExampleTable"
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity_units = 5
  write_capacity_units = 5

  attribute {
    name = "Id"
    type = "S"
  }

  key_schema = [
    {
      attribute_name = "Id"
      key_type       = "HASH"
    }
  ]

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "Id"
    read_capacity_units = 5
    write_capacity_units = 5
  }

  replication_config {
    region_name = "us-west-2"
  }

  replication_config {
    region_name = "us-west-1"
  }
}