provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_global_table" "example" {
  name         = "example-global-table"
  replicas     = ["us-east-1", "us-west-2"]
  billing_mode = "PAY_PER_REQUEST"
}