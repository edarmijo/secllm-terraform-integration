resource "aws_lambda_function" "test_lambda" {
  function_name = "test_lambda"
  handler        = "index.handler"
  role           = aws_iam_role.lambda_role.arn

  source_code_hash = filebase64sha256("lambda_function.zip")

  runtime = "python3.8"

  timeout = 10

  environment {
    variables = {
      region = var.region
    }
  }
}