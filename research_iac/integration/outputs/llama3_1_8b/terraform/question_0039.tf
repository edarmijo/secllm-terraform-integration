provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "codebuild_service_role" {
  name        = "CodeBuildServiceRole"
  description = "An IAM role for AWS CodeBuild service"

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
  role   = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
          "cloudwatch:GetMetricStatistics",
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:GetProjectAdminConfiguration"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_codebuild_project" "example" {
  name         = "example-codebuild-project"
  description  = "An example AWS CodeBuild project"

  source_type            = "GITHUB"
  source_location        = "https://github.com/your-username/your-repo-name.git"
  build_timeout           = 5
  queue_for_execution     = true

  environment {
    type             = " LINUX_CONTAINER "
    compute_type     = " BUILD_GENERAL1_SMALL "
    image            = "aws/codebuild/docker:17.12.0-nodejs-14.16.0"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}