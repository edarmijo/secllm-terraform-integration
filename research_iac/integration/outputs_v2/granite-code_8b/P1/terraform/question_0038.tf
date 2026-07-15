resource "aws_codebuild_project" "example" {
  name           = "example-project"
  build_spec     = file("buildspec.yml")

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE"
    image           = "aws/codebuild/standard:4.0"
    type            = "LINUX_CONTAINER"

    environment_variable {
      name  = "VAR_NAME"
      value = "var_value"
    }
  }

  service_role = aws_iam_role.codebuild.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec.yml")
  }

  secondary_sources {
    type      = "S3"
    location  = "s3://my-bucket/path/to/source"
    buildspec = "buildspec.yml"
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

  inline_policy {
    name = "CodeBuildPolicy"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "codecommit:GitPull"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket/path/to/source/*",
        "arn:aws:codecommit:us-east-1:123456789012:MyDemoRepo"
      ],
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  }
}