terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "codebuild_role" {
  name = "example-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
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
    Version = "2012-10-17",
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
  name         = "example-codebuild-project"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  secondary_artifacts {
    type     = "S3"
    location = "my-secondary-artifacts-bucket"
    path     = "/secondary"
    name     = "SecondaryArtifact"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ENV_VAR_1"
      value = "value1"
    }

    environment_variable {
      name  = "ENV_VAR_2"
      value = "value2"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/example/repo.git"
    git_clone_depth = 1
  }

  secondary_sources {
    type     = "BITBUCKET"
    location = "https://bitbucket.org/example/secondary-repo.git"
    name     = "SecondarySource"
  }
}