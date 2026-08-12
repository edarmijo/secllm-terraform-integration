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
  handler       = "index.handler"
  runtime       = "nodejs12.x"

  role {
    arn = aws_iam_role.lambda_executor.arn
  }
}

resource "aws_iam_role" "lambda_executor" {
  name               = "lambda-executor"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}