provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "s3_bucket_metrics_role" {
  name        = "S3BucketMetricsRole"
  description = "Allows S3 to publish metrics"

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

resource "aws_iam_policy" "s3_bucket_metrics_policy" {
  name        = "S3BucketMetricsPolicy"
  description = "Allows S3 to publish metrics"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:EnableAlarmActions",
          "cloudwatch:DisableAlarmActions"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_bucket_metrics_attach" {
  role       = aws_iam_role.s3_bucket_metrics_role.name
  policy_arn = aws_iam_policy.s3_bucket_metrics_policy.arn
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "mybucket"
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

resource "aws_s3_bucket_metrics" "mybucket_metrics" {
  bucket = aws_s3_bucket.mybucket.id

  name          = "MyBucketMetrics"
  namespace     = "AWS/S3"
  id_key        = "StorageBytesUsed"
  storage_class_key = "StorageClass"

  filter_prefix = ""
}