resource "aws_lexv2models_bot" "example" {
  name        = "example-bot"
  role_arn    = aws_iam_role.example.arn
  data_privacy = {
    child_directed = false
  }

  type = "Custom"

  idle_session_ttl_in_seconds = 300
  timeout_milliseconds         = 10000
}