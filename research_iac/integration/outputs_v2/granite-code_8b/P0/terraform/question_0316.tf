provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "video_content" {
  bucket = "my-video-site-content"

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
    domain_name = aws_s3_bucket.video_content.bucket_regional_domain_name
    origin_id   = "my-video-site-origin"

    custom_origin_config {
      http_port               = 80
      https_port              = 443
      read_timeout            = 30
      keepalive_timeout       = 5
      protocol_policy         = "https-only"
      origin_protocol_policy = "http-only"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "my-video-site-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

 Viewer_Certificate {
    cloudfront_default_certificate = true
  }
}