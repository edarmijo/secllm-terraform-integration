resource "aws_codebuild_project" "example" {
  name        = "example-project"
  description = "Example CodeBuild Project"

  service_role = aws_iam_role.example.arn

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    environment_variables {
      name  = "EXAMPLE_VARIABLE"
      value = "example-value"
    }
  }
}

resource "aws_iam_role" "example" {
  name               = "example-codebuild-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}