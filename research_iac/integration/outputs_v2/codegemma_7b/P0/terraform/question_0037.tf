provider "aws" {
  region = "us-east-1"
  iam_role = "arn:aws:iam::123456789012:role/codebuild-role"
}

resource "aws_codebuild_project" "example" {
  name = "example-project"

  source {
    type = "GITHUB"
    location = "github.com/example-user/example-repo.git"
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }
}