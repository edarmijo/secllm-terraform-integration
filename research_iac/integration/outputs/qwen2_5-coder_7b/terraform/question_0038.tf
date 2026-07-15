provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

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
  name   = "codebuild-policy"
  role   = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.example.bucket_arn}",
          "${aws_s3_bucket.example.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_codebuild_project" "example" {
  name             = "example-codebuild-project"
  role_arn         = aws_iam_role.codebuild_role.arn
  service_role     = aws_iam_role.codebuild_role.arn
  source_version   = "refs/heads/main"

  source {
    type          = "S3"
    location      = "${aws_s3_bucket.example.bucket}"
    buildspec     = "buildspec.yml"
    version       = "1.0"
  }

  secondary_sources {
    type          = "GITHUB"
    location      = "https://github.com/example/repo.git"
    branch        = "main"
    git_clone_depth = 1
    source_identifier = "secondary-source"
  }

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:4.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}