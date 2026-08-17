provider "aws" {
  region = "us-west-2"
}

# Create a secret for the S3 bucket name
resource "aws_secretsmanager_secret" "s3_bucket_name" {
  name = "s3_bucket_name"
}

resource "aws_secretsmanager_secret_version" "s3_bucket_name" {
  secret_id     = aws_secretsmanager_secret.s3_bucket_name.id
  secret_string = "example-bucket"
}

# Create a secret for the S3 bucket name for the second bucket
resource "aws_secretsmanager_secret" "s3_bucket_name_2" {
  name = "s3_bucket_name_2"
}

resource "aws_secretsmanager_secret_version" "s3_bucket_name_2" {
  secret_id     = aws_secretsmanager_secret.s3_bucket_name_2.id
  secret_string = "example-bucket-2"
}

# Create IAM role for S3 bucket
resource "aws_iam_role" "s3_bucket_role" {
  name        = "s3-bucket-role"
  description = "Role for S3 bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "s3-bucket-policy"
  description = "Policy for S3 bucket"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.example.arn,
          "${aws_s3_bucket.example.arn}/*",
        ]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.example_2.arn,
          "${aws_s3_bucket.example_2.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_bucket_attach" {
  role       = aws_iam_role.s3_bucket_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

# Create S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create S3 bucket
resource "aws_s3_bucket" "example_2" {
  bucket = "example-bucket-2"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create IAM role for logging
resource "aws_iam_role" "logging_role" {
  name        = "logging-role"
  description = "Role for logging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "logging_policy" {
  name        = "logging-policy"
  description = "Policy for logging"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.example_2.arn,
          "${aws_s3_bucket.example_2.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "logging_attach" {
  role       = aws_iam_role.logging_role.name
  policy_arn = aws_iam_policy.logging_policy.arn
}

# Create logging resource
resource "aws_cloudwatch_log_group" "example" {
  name = "example-log-group"

  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "example" {
  name           = "example-log-stream"
  log_group_name = aws_cloudwatch_log_group.example.name
}

resource "aws_s3_bucket_notification" "example" {
  bucket = aws_s3_bucket.example.id

  log {
    prefix = "log/"
    bucket = aws_s3_bucket.example_2.id
  }
}