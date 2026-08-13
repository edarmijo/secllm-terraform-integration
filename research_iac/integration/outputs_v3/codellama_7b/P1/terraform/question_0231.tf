resource "aws_dynamodb_table" "example" {
  name             = "example-table"
  billing_mode     = "PROVISIONED"
  read_capacity    = 5
  write_capacity   = 5
  server_side_encryption {
    enabled = true
  }
}