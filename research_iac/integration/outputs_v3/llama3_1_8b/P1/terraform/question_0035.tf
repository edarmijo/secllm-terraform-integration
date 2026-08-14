provider "aws" {
  region = "us-west-2"
}

data "aws_secretsmanager_secret" "codebuild_secret" {
  name = "example-codebuild-secret"
}

resource "aws_iam_role" "example_codebuild_role" {
  name               = "example-codebuild-role"
  description        = "Example IAM role for CodeBuild project"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
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
          "logs:PutEvent",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect = "Allow"
        Resource = aws_s3_bucket.example.arn
      }
    ]
  })
}

resource "aws_codebuild_project" "example_codebuild_project" {
  name         = "example-codebuild-project"
  description  = "Example CodeBuild project"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/docker:17.12.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true

    environment_variable {
      name  = "EXAMPLE_VAR"
      value = "example-value"
    }
  }

  source {
    type     = "NO_SOURCE"
  }

  tags = {
    Environment = "dev"
  }
}