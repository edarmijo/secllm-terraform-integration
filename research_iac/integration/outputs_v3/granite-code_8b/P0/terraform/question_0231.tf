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

  server_side_encryption {
    enabled     = true
    kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/abcd1234-a123-456b-a123-1234567890ab"
  }
}