provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "firehose_delivery_role" {
  name        = "${var.project_name}-kinesis-firehose-delivery-role"
  description = "Role for Kinesis Firehose Delivery Stream"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_delivery_policy" {
  name        = "${var.project_name}-kinesis-firehose-delivery-policy"
  description = "Policy for Kinesis Firehose Delivery Stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = aws_s3_bucket.firehose_delivery_bucket.arn
      },
      {
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
        ]
        Effect = "Allow"
        Resource = var.kinesis_stream_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_delivery_attach" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = aws_iam_policy.firehose_delivery_policy.arn
}

resource "aws_s3_bucket" "firehose_delivery_bucket" {
  bucket        = "${var.project_name}-kinesis-firehose-delivery-bucket"
  acl           = "private"

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

resource "aws_kinesis_firehose_delivery_stream" "firehose_delivery_stream" {
  name        = "${var.project_name}-kinesis-firehose-delivery-stream"
  destination = "s3"

  kinesis_source_configuration {
    role_arn            = aws_iam_role.firehose_delivery_role.arn
    stream_arn          = var.kinesis_stream_arn
    compression_format  = "GZIP"
    data_format_conversion_enabled = true

    dynamic_partitioning_enabled = true

    s3_bucket_arn = aws_s3_bucket.firehose_delivery_bucket.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_delivery_role.arn
    compression_format  = "GZIP"
    data_format_conversion_enabled = true

    dynamic_partitioning_enabled = true

    s3_bucket_arn = aws_s3_bucket.firehose_delivery_bucket.arn
  }
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_delivery_stream" {
  name        = "${var.project_name}-kinesis-firehose-delivery-stream"
  destination = "s3"

  kinesis_source_configuration {
    role_arn            = aws_iam_role.firehose_delivery_role.arn
    stream_arn          = var.kinesis_stream_arn
    compression_format  = "GZIP"
    data_format_conversion_enabled = true

    dynamic_partitioning_enabled = true

    s3_bucket_arn = aws_s3_bucket.firehose_delivery_bucket.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_delivery_role.arn
    compression_format  = "GZIP"
    data_format_conversion_enabled = true

    dynamic_partitioning_enabled = true

    s3_bucket_arn = aws_s3_bucket.firehose_delivery_bucket.arn
  }
}