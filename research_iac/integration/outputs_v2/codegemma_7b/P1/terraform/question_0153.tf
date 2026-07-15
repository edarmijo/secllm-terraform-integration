provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "my_lambda_function" {
  function_name = "my_lambda_function"
  runtime = "nodejs16.x"
  handler = "index.handler"
  code = filebase64("lambda_code.zip")
}

resource "aws_lambda_event_source_mapping" "my_event_source_mapping" {
  function_name = aws_lambda_function.my_lambda_function.function_name
  event_source_arn = aws_dynamodb_table.my_dynamodb_table.arn
  starting_position = "LATEST"
}

resource "aws_dynamodb_table" "my_dynamodb_table" {
  name = "my_dynamodb_table"
  hash_key = "id"
  billing_mode = "PAY_PER_REQUEST"
}