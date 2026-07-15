provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "codebuild_service_role" {
  name = "CodeBuildServiceRole"

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
  name   = "CodeBuildPolicy"
  role   = aws_iam_role.codebuild_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect = "Allow",
        Resource = "${aws_s3_bucket.codebuild_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "codebuild_bucket" {
  bucket = "my-codebuild-bucket-${random_string.suffix.result}"
}

resource "aws_codebuild_project" "example" {
  name                 = "ExampleCodeBuildProject"
  service_role         = aws_iam_role.codebuild_service_role.arn
  source_version       = "refs/heads/main"
  source_type          = "GITHUB"
  source_location      = "https://github.com/example/repo.git"
  environment_variables = [
    {
      name  = "EXAMPLE_VAR"
      value = "example_value"
      type  = "PLAINTEXT"
    }
  ]
  artifacts {
    location = aws_s3_bucket.codebuild_bucket.bucket
    type     = "S3"
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}