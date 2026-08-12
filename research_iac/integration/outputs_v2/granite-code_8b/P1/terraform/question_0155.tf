resource "aws_lambda_function" "example" {
  filename      = "lambda-function.zip"
  source_code_hash = filebase64sha256("lambda-function.zip")
  runtime    = "python3.8"
  handler     = "index.handler"

  environment {
    variables = {
      variable1 = "value1"
      variable2 = "value2"
    }
  }

  timeout = 30

  role = aws_iam_role.example.arn
}

resource "aws_cloudwatch_event_rule" "example" {
  name        = "example-rule"
  description = "Example rule"

  schedule_expression = "rate(15 minutes)"
}

resource "aws_lambda_permission" "example" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.example.arn
}