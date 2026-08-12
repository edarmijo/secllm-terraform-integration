provider "aws" {
  region = "us-west-1"
}

resource "aws_dynamodb_table" "example" {
  name           = "example"
  read_capacity  = 10
  write_capacity = 10

  attribute {
    name = "id"
    type = "S"
  }

  hash_key = "id"

  replica {
    region = "us-west-2"
  }
}