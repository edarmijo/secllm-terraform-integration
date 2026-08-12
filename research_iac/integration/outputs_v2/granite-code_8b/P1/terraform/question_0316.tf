provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "video_streaming_site" {
  bucket        = "my-video-streaming-site"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_cloudfront_distribution" "video_streaming_site" {
  origin {
    domain_name = aws_s3_bucket.video_streaming_site.bucket_regional_domain_name
    origin_id   = "my-video-streaming-site"

    custom_origin_config {
      http_port               = 80
      https_port              = 443
      origin_protocol_policy = "https-only"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "my-video-streaming-site"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl             = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_ restriction {
      restriction_type = "none"
    }
  }
}