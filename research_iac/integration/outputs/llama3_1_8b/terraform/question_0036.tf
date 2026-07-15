provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "codebuild_example" {
  name        = "CodeBuildExampleRole"
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

resource "aws_iam_role_policy" "codebuild_example" {
  name   = "CodeBuildExamplePolicy"
  role   = aws_iam_role.codebuild_example.id

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

resource "aws_codebuild_project" "example" {
  name         = "CodeBuildExampleProject"
  description  = "An example CodeBuild project"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/docker:17.12.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
  }

  source {
    type     = "GITHUB"
    location = "https://github.com/your-username/your-repo-name.git"

    buildspec   = file("./path/to/buildspec.yml")
    git_clone_depth = 0

    override_environment_variables = {
      REPO_NAME = "your-repo-name"
    }
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_cache.id
  }
}

resource "aws_s3_bucket" "codebuild_cache" {
  bucket = "codebuild-cache-bucket"

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