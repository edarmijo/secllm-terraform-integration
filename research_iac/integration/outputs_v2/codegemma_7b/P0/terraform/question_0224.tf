provider "aws" {
  region = "us-west-1"
}

resource "aws_dynamodb_table" "example" {
  name = "my_table"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  replica {
    region_name = "us-west-2"
  }
}