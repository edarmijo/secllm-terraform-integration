provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_dynamodb_table.example.stream_arn
  function_name = aws_lambda_function.example.arn

  starting_position = "LATEST"
}

resource "aws_dynamodb_table" "example" {
  name = "my_table"
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_lambda_function" "example" {
  function_name = "my_lambda_function"
  runtime = "nodejs14.x"
  handler = "index.handler"

  role = aws_iam_role.example.arn

  code = filebase64("lambda_code.zip")
}

resource "aws_iam_role" "example" {
  name = "my_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}