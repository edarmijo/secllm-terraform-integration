resource "aws_dynamodb_table" "example" {
  name             = "example"
  billing_mode     = "PROVISIONED"
  read_capacity    = 10
  write_capacity   = 5
  server_side_encryption {
    enabled = true
  }
}