provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudfront_distribution" "video_content_distribution" {
  origin {
    domain_name = aws_s3_bucket.video_content_bucket.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.video_content_origin_access_control.id
    origin_id = "s3_video_content_origin"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "s3_video_content_origin"
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_zone" "netflix_com" {
  name = "netflix.com"
}

resource "aws_route53_record" "video_content_domain" {
  zone_id = aws_route53_zone.netflix_com.zone_id
  name = "video.netflix.com"
  type = "A"
  alias {
    name = aws_cloudfront_distribution.video_content_distribution.domain_name
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_record" "video_content_redirect" {
  zone_id = aws_route53_zone.netflix_com.zone_id
  name = "netflix.com"
  type = "CNAME"
  alias {
    name = aws_cloudfront_distribution.video_content_distribution.domain_name
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_cloudfront_origin_access_control" "video_content_origin_access_control" {
  name = "video_content_origin_access_control"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}