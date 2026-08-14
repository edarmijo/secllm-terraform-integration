provider "aws" {
  region = "us-east-1"
  iam_role = "arn:aws:iam::123456789012:role/codebuild-role"
}

resource "aws_codebuild_project" "example" {
  name = "example-project"

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:latest"

    environment_variable {
      name = "MY_VARIABLE"
      value = "my_value"
    }
  }

  build_spec = "{}"
}