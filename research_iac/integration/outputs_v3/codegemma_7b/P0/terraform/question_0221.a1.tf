provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "example" {
  name = "my_table"

  attribute {
    name = "id"
    type = "S"
  }

  hash_key = "id"

  billing_mode = "PAY_PER_REQUEST"
}