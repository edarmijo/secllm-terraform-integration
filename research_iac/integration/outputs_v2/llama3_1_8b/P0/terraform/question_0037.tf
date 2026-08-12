provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "example_codebuild_role" {
  name        = "example-codebuild-role"
  description = "Example IAM role for CodeBuild"

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

resource "aws_iam_role_policy" "example_codebuild_policy" {
  name   = "example-codebuild-policy"
  role   = aws_iam_role.example_codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_codebuild_project" "example_codebuild_project" {
  name         = "example-codebuild-project"
  description  = "Example CodeBuild project"

  source {
    type     = "GITHUB"
    location = "https://github.com/your-username/your-repo-name.git"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/docker:17.12.0"
    type                        = "LINUX_CONTAINER"

    environment_variable {
      name  = "VARIABLE_NAME"
      value = "variable_value"
    }
  }

  logs_config {
    cloudwatch_logs_group_name = aws_cloudwatch_log_group.example_codebuild_log_group.name
    cloudwatch_logs_role_arn   = aws_iam_role.example_codebuild_role.arn
  }
}

resource "aws_cloudwatch_log_group" "example_codebuild_log_group" {
  name              = "example-codebuild-log-group"
  retention_in_days = 14
}