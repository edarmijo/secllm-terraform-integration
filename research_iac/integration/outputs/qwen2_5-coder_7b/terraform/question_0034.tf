provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_example_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild_example_policy"
  role   = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_codebuild_project" "example" {
  name     = "codebuild_example_project"
  role_arn = aws_iam_role.codebuild_role.arn

  source = {
    type              = "GITHUB"
    location          = "https://github.com/example/repo.git"
    git_clone_depth   = 1
    report_build_status = true
  }

  environment = {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:4.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = false

    environment_variables = [
      {
        name  = "EXAMPLE_VAR"
        value = "example_value"
        type  = "PLAINTEXT"
      },
    ]
  }

  cache = {
    type     = "S3"
    location = "s3://codebuild-example-cache"
  }
}