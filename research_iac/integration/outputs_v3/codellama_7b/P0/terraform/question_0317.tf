provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudfront_distribution" "video_streaming_site" {
  origin {
    domain_name = aws_s3_bucket.video_content.website_endpoint
    origin_id   = "videoContentBucket"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Video Streaming Site"
  default_root_object = "index.html"

  aliases = ["example.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "videoContentBucket"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_record" "video_streaming_site" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example.com."
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.video_streaming_site.domain_name
    zone_id                = aws_cloudfront_distribution.video_streaming_site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "video_content" {
  bucket        = "example-video-content"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}