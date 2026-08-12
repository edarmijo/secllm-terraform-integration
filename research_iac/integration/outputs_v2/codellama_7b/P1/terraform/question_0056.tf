provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_stream" "example" {
  name        = "example-stream"
  shard_count = 1
}