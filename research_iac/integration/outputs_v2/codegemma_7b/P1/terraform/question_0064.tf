provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name = "my-firehose-stream"

  source_prefix = "my-source-prefix"

  destination {
    type = "opensearchservice"

    configuration {
      buffering_interval = 43200
      buffering_size = 52428800
      cloudwatch_logging_enabled = true
      endpoint = "my-opensearch-domain.us-east-1.es.amazonaws.com"
      index_name = "my-index"
      role_arn = aws_iam_role.firehose_role.arn
      retry_duration = 3600
      s3_backup_mode = "enabled"
      s3_configuration {
        bucket_arn = aws_s3_bucket.firehose_bucket.arn
        prefix = "firehose-data"
      }
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  managed_policy {
    name = "firehose-policy"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        aws_s3_bucket.firehose_bucket.arn,
        "${aws_s3_bucket.firehose_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "es:ESHttpPost",
        "es:ESHttpPut",
        "es:ESHttpGet",
        "es:ESHttpDelete"
      ],
      "Resource": "my-opensearch-domain.us-east-1.es.amazonaws.com/*"
    }
  ]
}
EOF
  }
}

resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "my-firehose-bucket"
}