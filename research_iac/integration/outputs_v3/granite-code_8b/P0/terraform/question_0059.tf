resource "aws_kinesis_firehose_delivery_stream" "example" {
  name           = "example-firehose-delivery-stream"
  destination    = "extended_s3"

  extended_s3_destination {
    bucket_arn                   = aws_s3_bucket.example.arn
    role_arn                     = aws_iam_role.firehose.arn
    buffering_hints {
      interval_in_seconds  = 60
      size_in_mib          = 5
    }
    compression_format = "UNCOMPRESSED"
    dynamic_partitioning_configuration {
      enabled = true
    }
  }
}