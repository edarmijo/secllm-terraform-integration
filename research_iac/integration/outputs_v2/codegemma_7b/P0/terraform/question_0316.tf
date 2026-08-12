provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "video_content" {
  bucket = "video-content-bucket"
}

resource "aws_cloudfront_distribution" "video_distribution" {
  origins {
    domain_name = aws_s3_bucket.video_content.bucket_domain_name
    origin_id = "video-content-origin"
  }

  enabled = true

  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn = "YOUR_ACM_CERTIFICATE_ARN"
  }
}