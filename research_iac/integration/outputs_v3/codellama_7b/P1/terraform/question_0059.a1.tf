resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "example-firehose-stream"
  destination = "s3"

  extended_s3_destination_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    bucket_arn         = aws_s3_bucket.example.arn
    buffering_interval = 60
    buffering_size     = 10
    compression_format = "GZIP"

    dynamic_partitioning {
      enabled = true
    }
  }
}