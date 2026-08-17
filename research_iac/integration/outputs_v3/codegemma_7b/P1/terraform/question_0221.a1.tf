provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "example_table" {
  name = "example_table"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  hash_key = "id"

  provisioner "local-exec" {
    command = "aws dynamodb create-table --table-name example_table --attribute-definitions name=id,type=S,name=name,type=S --key-schema AttributeName=id,KeyType=HASH --billing-mode PAY_PER_REQUEST"
  }
}