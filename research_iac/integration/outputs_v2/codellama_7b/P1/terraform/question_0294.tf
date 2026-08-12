provider "aws" {
  region = "us-east-1"
}

resource "aws_codebuild_project" "autograder" {
  name        = "autograder"
  description = "Autograder for CS class"

  source {
    type            = "GITHUB"
    location        = "https://github.com/example-org/example-repo"
    git_clone_depth = 1
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    environment_variables {
      name  = "GITHUB_TOKEN"
      value = var.github_token
    }
  }

  artifacts {
    type = "S3"
    location = aws_s3_bucket.autograder_artifacts.id
  }
}

resource "aws_s3_bucket" "autograder_artifacts" {
  bucket        = "autograder-artifacts"
  acl           = "private"
  force_destroy = true
}