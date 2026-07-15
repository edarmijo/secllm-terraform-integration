provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "example" {
  name = "secure_table"

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "id"
    type = "S"
  }

  key_schema {
    attribute_name = "id"
    key_type       = "HASH"
  }
}