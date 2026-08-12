provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "codebuild" {
  name               = "codebuild-role"
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

resource "aws_iam_role_policy" "codebuild" {
  name   = "codebuild-policy"
  role   = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      },
      {
        Action = [
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_codebuild_project" "autograder" {
  name           = "autograder-project"
  service_role   = aws_iam_role.codebuild.arn
  source         = {
    type      = "GITHUB"
    location  = var.github_repo
    buildspec = file("buildspec.yml")
  }
  artifacts     = {
    type = "NO_ARTIFACTS"
  }
  environment   = {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/standard:4.0"
    privileged_mode = false
  }
}