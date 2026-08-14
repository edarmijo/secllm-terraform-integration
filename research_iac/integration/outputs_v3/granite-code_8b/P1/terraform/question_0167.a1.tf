# Create DynamoDB Global Table
resource "aws_dynamodb_global_table" "example" {
  name             = "example-global-table"
  region           = "us-west-2"
  hash_key         = "id"
  billing_mode     = "PROVISIONED"
  write_capacity   = 10
  read_capacity    = 10

  range_key        = "time"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "time"
    type = "N"
  }

  replica {
    region           = "us-east-1"
  }
}