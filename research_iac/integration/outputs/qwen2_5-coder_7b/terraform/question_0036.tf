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
  name = "codebuild-policy"
  role = aws_iam_role.codebuild_role.id

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
          "s3:PutObject",
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.codebuild_cache.arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket" "codebuild_cache" {
  bucket = "codebuild-cache-bucket-${random_string.suffix.result}"
}

resource "aws_codebuild_project" "example" {
  name            = "example-codebuild-project"
  service_role    = aws_iam_role.codebuild_role.arn
  source          = {
    type              = "GITHUB"
    location          = "https://github.com/your-repo/your-repo.git"
    git_clone_depth   = 1
    report_build_status = true
  }
  artifacts         = {
    type = "NO_ARTIFACTS"
  }
  cache             = {
    type     = "S3"
    location = aws_s3_bucket.codebuild_cache.arn
  }
  environment       = {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:5.0"
    compute_type      = "BUILD_GENERAL1_SMALL"
    privileged_mode   = false
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = true
}