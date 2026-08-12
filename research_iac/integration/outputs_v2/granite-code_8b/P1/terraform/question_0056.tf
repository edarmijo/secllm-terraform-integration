resource "aws_kinesis_stream" "example" {
  name           = "example-stream"
  shard_count    = 1
  encryption_type = "KMS"
  kms_key_id     = aws_kms_key.example.arn

  tags = {
    Environment = "production"
  }
}