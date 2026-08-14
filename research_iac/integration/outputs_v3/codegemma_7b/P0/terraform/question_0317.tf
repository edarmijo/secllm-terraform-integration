provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "video_content" {
  bucket = "video-content"
}

resource "aws_cloudfront_distribution" "video_distribution" {
  origin {
    domain_name = aws_s3_bucket.video_content.bucket_domain_name
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    default_ttl = 3600
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