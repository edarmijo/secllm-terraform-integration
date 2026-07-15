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
  name            = "codebuild_example_project"
  service_role    = aws_iam_role.codebuild_role.arn
  source          = {
    type              = "S3"
    location          = "s3://your-bucket/your-source-code.zip"
    buildspec         = "buildspec.yml"
    version           = "1.0"
  }
  artifacts       = {
    type            = "NO_ARTIFACTS"
  }
  secondary_artifacts = [
    {
      name              = "secondary-artifact"
      location          = "s3://your-bucket/secondary-artifact"
      type              = "S3"
      packaging         = "ZIP"
      encryptionEnabled = true
      encryptionKey     = aws_kms_key.codebuild_encryption.arn
    },
  ]
}

resource "aws_kms_key" "codebuild_encryption" {
  description = "KMS key for CodeBuild artifact encryption"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}