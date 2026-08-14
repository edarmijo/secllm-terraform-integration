provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "glacier_vault_access_policy" {
  name        = "GlacierVaultAccessPolicyRole"
  description = "Role for accessing Glacier vault"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glacier.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "glacier_vault_access_policy" {
  name   = "GlacierVaultAccessPolicy"
  role   = aws_iam_role.glacier_vault_access_policy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.glacier_vault.arn
      },
    ]
  })
}

resource "aws_s3_bucket" "glacier_vault" {
  bucket = "my-glacier-vault"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_policy" "glacier_vault_access_policy" {
  bucket = aws_s3_bucket.glacier_vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowGlacierAccess"
        Effect    = "Allow"
        Principal = {
          Service = "glacier.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = aws_s3_bucket.glacier_vault.arn
      },
    ]
  })
}

resource "aws_glacier_vault" "my_vault" {
  name = "my-glacier-vault"

  access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowGlacierAccess"
        Effect    = "Allow"
        Principal = {
          Service = "glacier.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = aws_s3_bucket.glacier_vault.arn
      },
    ]
  })
}