provider "aws" {
  region = "us-west-1"
}

resource "aws_dynamodb_table" "example" {
  name = "my_table"

  hash_key = "id"

  billing_mode = "PAY_PER_REQUEST"

  replica {
    region_name = "us-west-2"
  }
}