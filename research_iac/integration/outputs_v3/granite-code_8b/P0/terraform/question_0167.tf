provider "aws" {
  region = var.region
}

resource "aws_dynamodb_global_table" "example" {
  name             = "example-global-table"
  hash_key         = "id"
  billing_mode     = "PROVISIONED"
  read_capacity    = 10
  write_capacity   = 10

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "example_ replica" {
  name           = "example-global-table-replica"
  read_capacity  = 5
  write_capacity = 5

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "id"
    type = "S"
  }

  global_ secondary_index {
    name            = "example-global-table- replica-index"
    hash_key        = "id"
    read_capacity   = 5
    write_capacity  = 5
    projection_type = "INCLUDE"

    non_key_attributes = [
      "attribute1",
      "attribute2",
    ]
  }
}