resource "aws_codebuild_project" "example" {
  name           = "example-project"
  service_role   = aws_iam_role.codebuild.arn
  build_spec     = file("buildspec.yml")

  environment {
    variables = {
      example_variable = "example value"
    }
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