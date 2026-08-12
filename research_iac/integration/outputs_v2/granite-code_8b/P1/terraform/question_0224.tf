resource "aws_dynamodb_table" "example" {
  name           = "example"
  read_capacity  = 10
  write_capacity = 10

  attribute {
    name = "id"
    type = "S"
  }

  key_schema {
    attribute_name = "id"
    key_type       = "HASH"
  }

  replica {
    region_name = "us-west-1"
  }

  replica {
    region_name = "us-west-2"
  }
}