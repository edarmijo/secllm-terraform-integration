provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "codebuild_role" {
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
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "CodeBuildPolicy"
  role   = aws_iam_role.codebuild_role.id

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
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.codebuild_artifacts.arn}"
      }
    ]
  })
}

resource "aws_codebuild_project" "example" {
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
      name  = "AWS_REGION"
      value = "us-west-2"
    }
    environment_variable {
      name  = "CODEBUILD_PROJECT_NAME"
      value = aws_codebuild_project.example.name
    }

    cache {
      location = "/cache"
      modes    = ["LOCAL_SOURCE_CACHE"]
    }
  }
}

resource "aws_s3_bucket" "codebuild_artifacts" {
  bucket = "your-bucket-name"
}