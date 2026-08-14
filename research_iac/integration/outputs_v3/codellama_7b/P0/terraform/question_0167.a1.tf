provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_global_table" "example" {
  name         = "example-global-table"
  replica {
    region_name = "us-east-1"
  }
  replica {
    region_name = "us-west-2"
  }
  billing_mode = "PAY_PER_REQUEST"
}