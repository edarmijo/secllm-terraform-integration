resource "aws_lambda_function" "reduce_database_calls" {
  function_name = "ReduceDatabaseCalls"
  runtime       = "nodejs14.x"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_executor.arn
  filename      = "lambda-function.zip"
}

resource "aws_iam_role" "lambda_executor" {
  name               = "LambdaExecutorRole"
  assume_role_policy = file("${path.module}/policies/assume-role-policy.json")
}

resource "aws_iam_policy" "lambda_executor" {
  name        = "LambdaExecutorPolicy"
  description = "Policy for Lambda Executor Role"
  policy      = file("${path.module}/policies/lambda-executor-policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_executor" {
  role       = aws_iam_role.lambda_executor.name
  policy_arn = aws_iam_policy.lambda_executor.arn
}