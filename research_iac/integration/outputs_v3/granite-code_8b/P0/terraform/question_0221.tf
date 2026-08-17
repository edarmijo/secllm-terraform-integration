resource "aws_dynamodb_table" "example" {
  name           = "example"
  read_capacity  = 10
  write_capacity = 10

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "data"
    type = "S"
  }

  key {
    name = "id"
    type = "S"
  }

  lifecycle {
    prevent_destroy = false
  }
}