provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "example" {
  name = "codebuild-example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "example" {
  name = "codebuild-example-policy"
  role = aws_iam_role.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_codebuild_project" "example" {
  name     = "codebuild-example-project"
  role_arn = aws_iam_role.example.arn

  environment {
    type                 = "LINUX_CONTAINER"
    image                = "aws/codebuild/standard:5.0"
    compute_type         = "BUILD_GENERAL1_SMALL"
    privileged_mode      = false
    environment_variables = [
      {
        name  = "EXAMPLE_VAR"
        value = "example_value"
      },
    ]
  }
}