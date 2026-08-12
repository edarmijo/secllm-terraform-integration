provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "video_content" {
  bucket = "video-content-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "delete-old-objects"
    prefix  = ""
    enabled = true

    expiration {
      days = 30
    }
  }
}

resource "aws_cloudfront_distribution" "video_streaming" {
  origin {
    domain_name = aws_s3_bucket.video_content.bucket_regional_domain_name
    origin_id   = "video-content-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.video_streaming.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Video Streaming Site"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.video_content.logging_bucket
  }

  aliases = ["example.com"]

  default_cache_behavior {
    target_origin_id = "video-content-bucket"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true
    min_ttl          = 0
    default_ttl      = 3600
    max_ttl          = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "video_streaming" {
  comment = "Video Streaming Site"
}