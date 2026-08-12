resource "aws_kinesis_stream" "example" {
  name           = "example-stream"
  shard_count    = 1
  retention_period = 86400

  tags = {
    Name = "example-stream"
  }
}