resource "aws_dynamodb_table" "example" {
  name = "my_table"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption_configuration {
    enabled = true
  }
}