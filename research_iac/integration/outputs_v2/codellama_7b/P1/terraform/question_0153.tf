resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_dynamodb_table.example.stream_arn
  function_name    = aws_lambda_function.example.arn
}

resource "aws_dynamodb_table" "example" {
  name         = "example-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_lambda_function" "example" {
  filename      = "example.zip"
  function_name = "example"
  role          = aws_iam_role.example.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"
}

resource "aws_iam_role" "example" {
  name               = "example-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}