resource "aws_lexv2models_bot" "example" {
  name = "example_bot"
  role_arn = "YOUR_ROLE_ARN"
  idle_session_ttl_in_seconds = 3600
}