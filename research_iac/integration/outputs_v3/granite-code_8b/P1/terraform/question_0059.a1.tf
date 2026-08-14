resource "aws_kinesis_firehose_delivery_stream" "example" {
  name           = "example-firehose-delivery-stream"
  destination    = "s3"

  s3_destination {
    bucket_arn                   = aws_s3_bucket.example.arn
    role_arn                     = aws_iam_role.firehose_role.arn
    buffering_hints {
      interval_in_seconds  = 60
      size_in_mbytes       = 5
    }
    compression_format          = "UNCOMPRESSED"
    cloudwatch_logging_options {
      enabled      = false
      log_group_name   = null
      log_stream_name = null
    }
  }

  server_side_encryption {
    enabled = true
    encryption_type = "AES256"
  }
}