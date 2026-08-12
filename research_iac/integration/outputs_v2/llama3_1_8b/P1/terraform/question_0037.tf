provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

module "example_iam_role" {
  source = "./modules/example-iam-role"

  role_name        = "ExampleCodeBuildRole"
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

module "example_codebuild_project" {
  source = "./modules/example-codebuild-project"

  project_name       = "ExampleCodeBuildProject"
  role_arn           = module.example_iam_role.role_arn
  source_type        = "GITHUB"
  source_location   = "https://github.com/username/repository.git"
  environment_type = " LINUX_CONTAINER"

  logs_config {
    cloudwatch_logs_group_name = "example-codebuild-project-logs-group"
    cloudwatch_logs_stream_name = "example-codebuild-project-logs-stream"
  }
}

module "example_iam_role" {
  source = "./modules/example-iam-role"

  role_name        = "ExampleCodeBuildRole"
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

resource "aws_codebuild_project" "example" {
  name         = var.project_name
  description  = "Example CodeBuild Project"
  build_timeout = 10
  service_role  = module.example_iam_role.role_arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/docker:17.12.0-nodejs-14.16.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
  }
}