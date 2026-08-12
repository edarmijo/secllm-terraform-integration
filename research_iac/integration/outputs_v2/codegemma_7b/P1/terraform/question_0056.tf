provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_stream" "example" {
  name = "my-stream"
}