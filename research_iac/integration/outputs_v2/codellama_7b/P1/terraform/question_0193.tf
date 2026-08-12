resource "aws_lambda_function" "reduce_database_calls" {
  function_name = "reduce-database-calls"
  runtime       = "python3.8"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_executor.arn
  timeout       = 10

  environment {
    variables = {
      DB_HOST     = var.db_host
      DB_USERNAME = var.db_username
      DB_PASSWORD = var.db_password
    }
  }
}