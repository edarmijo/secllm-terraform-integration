provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "dynamodb_global_table_exec_role" {
  name        = "DynamoDBGlobalTableExecRole"
  description = "Execution role for DynamoDB Global Table"

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

resource "aws_iam_policy" "dynamodb_global_table_exec_policy" {
  name        = "DynamoDBGlobalTableExecPolicy"
  description = "Execution policy for DynamoDB Global Table"

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
          "dynamodb:DescribeTable"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_global_table_exec_attach" {
  role       = aws_iam_role.dynamodb_global_table_exec_role.name
  policy_arn = aws_iam_policy.dynamodb_global_table_exec_policy.arn
}

resource "aws_dynamodb_table" "example_table" {
  name           = "ExampleTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  global_secondary_index {
    name         = "gsi1"
    hash_key     = "gsi1-sort-key"
    range_key     = "gsi1-sort-key"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table_replication_configuration" "example_table_global" {
  table_name       = aws_dynamodb_table.example_table.name
  replication_group_id = "ExampleTableReplicationGroup"

  region_configuration {
    region_name            = "us-west-2"
    replica_region        = "eu-central-1"
    primary_key           = "id"
    global_secondary_indexes = [
      {
        index_name       = "gsi1"
        hash_key         = "gsi1-sort-key"
        range_key        = "gsi1-sort-key"
        projection_type  = "ALL"
      }
    ]
  }
}