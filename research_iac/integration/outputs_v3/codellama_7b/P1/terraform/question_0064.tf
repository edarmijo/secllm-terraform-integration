provider "aws" {
  region = "us-east-1"
}

resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "example-firehose-delivery-stream"
  destination = "opensearch"

  opensearch_configuration {
    domain_arn = aws_opensearch_domain.example.arn
    index_name = "my-index"
  }
}

resource "aws_opensearch_domain" "example" {
  name      = "example-opensearch-domain"
  version   = "7.10"
  instance_type = "t3.small"
}