provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_global_table" "global_table" {
  name = "my_global_table"

  replica {
    region_name = "us-west-2"
  }
}