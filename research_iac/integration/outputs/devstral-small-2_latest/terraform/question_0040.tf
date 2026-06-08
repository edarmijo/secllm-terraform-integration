provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "codebuild_role" {
  name = "example-codebuild-role"

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
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_codebuild_project" "example" {
  name          = "example-codebuild-project"
  description   = "Example CodeBuild project with build batch configuration"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/example/repo.git"
    git_clone_depth = 1
  }

  build_batch_config {
    service_role = aws_iam_role.codebuild_role.arn

    batch_report_mode = "INDIVIDUAL_REPORTS"

    timeout_in_mins = 60

    compute_types = ["BUILD_GENERAL1_MEDIUM"]
  }
}