resource "aws_lexv2models_bot" "example" {
  name        = "ExampleBot"
  description = "This is an example bot"
  role_arn    = aws_iam_role.example.arn
  data_privacy {
    child_directed = false
  }
}

resource "aws_iam_role" "example" {
  name        = "ExampleBotRole"
  description = "This is an example role for the bot"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lex.amazonaws.com"
        }
      },
    ]
  })
}