resource "aws_kinesis_firehose_delivery_stream" "example" {
  name           = "example-delivery-stream"
  destination    = "arn:aws:es:us-west-2:123456789012:domain/example-domain"
  server_side_encryption {
    enabled = true
  }
}