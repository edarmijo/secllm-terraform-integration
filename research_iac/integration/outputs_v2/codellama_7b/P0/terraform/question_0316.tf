provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "video_streaming_site" {
  bucket = "video-streaming-site"
  acl    = "public-read"
}

resource "aws_cloudfront_distribution" "video_streaming_site" {
  origin {
    domain_name = aws_s3_bucket.video_streaming_site.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.video_streaming_site.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["video-streaming-site.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.video_streaming_site.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}