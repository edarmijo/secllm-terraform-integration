resource "aws_iam_role" "codebuild" {
  name = "example-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "example" {
  name           = "example-project"
  service_role   = aws_iam_role.codebuild.arn
  build_spec     = file("build-spec.yml")

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/standard:4.0"
    type            = "LINUX_CONTAINER"

    environment_variable {
      name  = "EXAMPLE_VARIABLE"
      value = "example-value"
    }
  }
}