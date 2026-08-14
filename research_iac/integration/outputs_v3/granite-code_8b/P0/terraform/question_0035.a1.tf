resource "aws_codebuild_project" "example" {
  name           = "example-project"
  service_role   = aws_iam_role.codebuild.arn
  build_spec     = file("buildspec.yml")

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/standard:2.0"
    type         = "LINUX_CONTAINER"

    variables = {
      example_variable = "example value"
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("buildspec.yml")
  }
}

resource "aws_iam_role" "codebuild" {
  name = "codebuild-role"

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