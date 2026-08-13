resource "aws_dynamodb_table" "example" {
  name           = "example"
  read_capacity  = 10
  write_capacity = 10

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.example.arn
  }
}