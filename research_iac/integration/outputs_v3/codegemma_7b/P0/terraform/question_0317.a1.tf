provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "video_content" {
  bucket = "video-content"
}

resource "aws_cloudfront_distribution" "video_distribution" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.video_content.bucket_domain_name
    origin_id = "video-content-origin"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    default_ttl = 3600
    target_origin_id = "video-content-origin"
    viewer_protocol_policy = "allow-all"
  }

  viewer_certificate {
    acm_certificate_arn = "YOUR_CERTIFICATE_ARN"
  }
}

resource "aws_route53_record" "video_domain" {
  name = "example.com"
  type = "A"
  alias {
    name = aws_cloudfront_distribution.video_distribution.domain_name
    zone_id = aws_cloudfront_distribution.video_distribution.hosted_zone_id
  }
}