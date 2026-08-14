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

resource "aws_dynamodb_global_table" "example" {
  name         = aws_dynamodb_table.example.name
  replica {
    region_name = "us-east-1"
  }

  replica {
    region_name = "us-west-2"
  }
}