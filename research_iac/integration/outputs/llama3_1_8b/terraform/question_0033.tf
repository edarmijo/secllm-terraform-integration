provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "codebuild-role" {
  name        = "CodeBuildRole"
  description = "An IAM role for CodeBuild"

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

resource "aws_iam_role_policy" "codebuild-policy" {
  name   = "CodeBuildPolicy"
  role   = aws_iam_role.codebuild-role.id

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
    ]
  })
}

resource "aws_codebuild_project" "example-project" {
  name         = "ExampleCodeBuildProject"
  description  = "An example CodeBuild project"

  source {
    type     = "GITHUB"
    location = "https://github.com/your-username/your-repo-name.git"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/docker:17.12.0"
    type                        = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-west-2"
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  service_role = aws_iam_role.codebuild-role.arn
}