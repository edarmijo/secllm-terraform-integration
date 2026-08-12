provider "aws" {
  region = "us-east-1"
}

resource "aws_codebuild_project" "autograder" {
  name        = "cs-class-autograder"
  description = "Autograder for CS class"

  source {
    type      = "GITHUB"
    location  = "https://github.com/example-org/example-repo"
    buildspec = "buildspec.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    environment_variables {
      name  = "GITHUB_TOKEN"
      value = "your-github-token"
    }
  }

  artifacts {
    type = "S3"
    location = "s3://example-bucket/autograder-results"
  }
}