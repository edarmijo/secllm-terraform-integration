provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "example_codebuild_role" {
  name        = "example-codebuild-role"
  description = "Example IAM Role for CodeBuild"

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
          "logs:PutEvent",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:GetBlob",
          "codecommit:GetObject",
        ]
        Effect = "Allow"
        Resource = aws_codecommit_repository.example.arn
      },
    ]
  })
}

resource "aws_codebuild_project" "example" {
  name         = "example-codebuild-project"
  description  = "Example CodeBuild Project"

  source         = "GITHUB"
  source_version = "main"
  source_info {
    location        = "https://github.com/username/repository.git"
    type            = "GITHUB"
    auth_type       = "OAUTH"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/docker:17.12.0-nodejs-14.16.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
  }
}

resource "aws_codecommit_repository" "example" {
  repository_name = "example-codecommit-repo"
}