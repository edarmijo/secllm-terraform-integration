resource "aws_dynamodb_table" "example" {
  name             = "example"
  billing_mode     = "PROVISIONED"
  read_capacity    = 5
  write_capacity   = 5
  hash_key         = "id"
  range_key        = "range_key"
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "range_key"
    type = "S"
  }
  tags = {
    Name = "example"
  }
}