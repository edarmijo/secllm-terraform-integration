resource "aws_s3_bucket_metric" "mybucket_metrics" {
  bucket = aws_s3_bucket.mybucket.id
  name = "mybucket_metrics"

  metrics {
    prefix = ""
    enabled = true
  }
}