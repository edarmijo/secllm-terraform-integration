resource "aws_lambda_function" "my_lambda" {
  filename      = "lambda_function.zip"
  function_name = "my-lambda-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "exports.handler"
  runtime       = "nodejs12.x"

  source_code_hash = filebase64sha256("lambda_function.zip")

  timeout = 30

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_cloudwatch_event_rule" "my_rule" {
  name                = "my-rule"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_function" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.my_rule.arn
}