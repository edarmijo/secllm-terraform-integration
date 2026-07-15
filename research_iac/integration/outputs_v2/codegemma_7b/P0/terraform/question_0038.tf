provider "aws" {
  region = "us-east-1"
  iam_role = "arn:aws:iam::123456789012:role/terraform-codebuild-role"
}

resource "aws_codebuild_project" "example" {
  name = "example-codebuild-project"

  source {
    type = "GITHUB"
    location = "github.com/example-user/example-repo.git"
  }

  secondary_source {
    type = "CODECOMMIT"
    location = "codecommit://example-codecommit-repo"
  }

  build_spec = file("buildspec.yml")
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:latest"
  }
}