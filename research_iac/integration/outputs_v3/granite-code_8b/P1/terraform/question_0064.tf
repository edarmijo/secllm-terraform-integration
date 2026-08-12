resource "aws_kinesis_firehose_delivery_stream" "example" {
  name = "example-delivery-stream"

  serverless_configuration {
    buffering_hints {
      interval_in_seconds 60
      size_in_mib         5
    }

    cloudwatch_logging_options {
      enabled      = true
      log_group_name   = aws_cloudwatch_log_group.example.name
      log_stream_name = "firehose-delivery-stream"
    }

    data_processing_configuration {
      inputs = [
        {
          input_id = "example-input"

          kinesis_stream_source_description {
            kinesis_stream_arn = aws_kinesis_stream.example.arn
            role_arn             = aws_iam_role.firehose.arn
          }
        },
      ]
    }

    retry_options {
      duration_in_seconds = 60
    }

    s3_configuration {
      bucket_arn       = aws_s3_bucket.example.arn
      buffering_hints {
        interval_in_seconds = 60
        size_in_mib         = 5
      }
      compression_format     = "UNCOMPRESSED"
      error_output_prefix    = "error/"
      prefix                 = "documents/"
    }

    role_arn = aws_iam_role.firehose.arn
  }
}