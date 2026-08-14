provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "firehose_delivery_role" {
  name        = "FirehoseDeliveryRole"
  description = "For Kinesis Firehose Delivery Stream"

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
  name        = "FirehoseDeliveryPolicy"
  description = "For Kinesis Firehose Delivery Stream"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_delivery_attach" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = aws_iam_policy.firehose_delivery_policy.arn
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "ExampleDeliveryStream"
  destination = "s3"

  s3_configuration {
    role_arn            = aws_iam_role.firehose_delivery_role.arn
    compression_format  = "GZIP"
    compression_type    = "GZIP"
    data_format         = "JSON"
    encoding_format     = "UTF-8"
    error_notification_arn = ""
    bucket_arn          = "arn:aws:s3:::<your-bucket-name>"
    role_arn            = aws_iam_role.firehose_delivery_role.arn
  }

  dynamic_partitioning {
    enabled = true

    s3_bucket_target {
      bucket_name = "arn:aws:s3:::<your-bucket-name>"

      compression_format = "GZIP"
      compression_type   = "GZIP"
      data_format        = "JSON"
      encoding_format    = "UTF-8"
    }
  }

  tags = {
    Name = "ExampleDeliveryStream"
  }
}