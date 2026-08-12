provider "aws" {
  region = "us-west-2"
}

resource "aws_codebuild_project" "autograder" {
  name         = "cs-class-autograder"
  description  = "Autograder for CS class"

  source {
    type     = "GITHUB"
    location = "https://github.com/your-github-username/cs-class-repo.git"
    buildspec = file("./buildspec.yml")
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

  service_role = aws_iam_role.autograder.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

resource "aws_codebuild_project" "result_storage" {
  name         = "cs-class-result-storage"
  description  = "Store autograder results for CS class"

  source {
    type     = "GITHUB"
    location = "https://github.com/your-github-username/cs-class-repo.git"
    buildspec = file("./buildspec.yml")
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

  service_role = aws_iam_role.result_storage.arn

  artifacts {
    type            = "CODEPIPELINE"
    packaging       = "NONE"
    override_artifact_name = true
  }
}

resource "aws_iam_role" "autograder" {
  name        = "cs-class-autograder-execution-role"
  description = "Execution role for autograder"

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

resource "aws_iam_role_policy" "autograder" {
  name   = "cs-class-autograder-execution-policy"
  role   = aws_iam_role.autograder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
        ]
        Effect   = "Allow"
        Resource = aws_codebuild_project.autograder.arn
      }
    ]
  })
}

resource "aws_iam_role" "result_storage" {
  name        = "cs-class-result-storage-execution-role"
  description = "Execution role for result storage"

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

resource "aws_iam_role_policy" "result_storage" {
  name   = "cs-class-result-storage-execution-policy"
  role   = aws_iam_role.result_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutEvent",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.result_storage.arn
      }
    ]
  })
}

resource "aws_s3_bucket" "result_storage" {
  bucket = "cs-class-result-storage"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 30
    }
  }
}