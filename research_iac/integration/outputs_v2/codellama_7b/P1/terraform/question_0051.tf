provider "aws" {
  region = "us-east-1"
}

resource "aws_lexv2models_bot" "example" {
  name        = "ExampleBot"
  description = "This is an example bot."
  role_arn    = aws_iam_role.example.arn
  data_privacy {
    child_directed = false
  }
}

resource "aws_iam_role" "example" {
  name               = "ExampleBotRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lexv2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}