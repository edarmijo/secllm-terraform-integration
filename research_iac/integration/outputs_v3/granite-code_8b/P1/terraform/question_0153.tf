resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_dynamodb_table.example.arn
  function_name    = aws_lambda_function.example.arn
  batch_size       = 100
}