resource "aws_s3_bucket" "mybucket" {
  bucket = "mybucket"
}

resource "aws_s3_bucket_metric" "mybucket-metrics" {
  bucket = aws_s3_bucket.mybucket.id
  name   = "EntireBucketMetrics"
}