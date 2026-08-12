provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "example" {
  name         = "example-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table_replica" "us-west-1" {
  table_name          = aws_dynamodb_table.example.name
  region              = "us-west-1"
  read_capacity       = 5
  write_capacity      = 5
}

resource "aws_dynamodb_table_replica" "us-west-2" {
  table_name          = aws_dynamodb_table.example.name
  region              = "us-west-2"
  read_capacity       = 5
  write_capacity      = 5
}