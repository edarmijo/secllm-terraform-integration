provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_kendra_data_source" "example" {
  name        = "Example DataSource"
  index_id    = aws_kendra_index.example.id
  provider_type = "S3"

  configuration {
    s3_configuration {
      bucket_name = var.s3_bucket_name
      ingestion_role_arn = aws_iam_role.kendra_data_source.arn

      url_exclusion_patterns = [
        "s3://example-bucket/exclude-me/*",
      ]

      url_inclusion_patterns = [
        "s3://example-bucket/include-me/*",
      ]
    }
  }
}

resource "aws_kendra_index" "example" {
  name            = "Example Index"
  description     = "An example index for Kendra"
  server_side_token_configuration {
    client_tokens {
      enabled = true
    }
  }
}

resource "aws_iam_role" "kendra_data_source" {
  name        = "KendraDataSourceRole"
  description = "Role for Kendra data source"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kendra.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "kendra_data_source" {
  name        = "KendraDataSourcePolicy"
  description = "Policy for Kendra data source"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = var.s3_bucket_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kendra_data_source" {
  role       = aws_iam_role.kendra_data_source.name
  policy_arn = aws_iam_policy.kendra_data_source.arn
}