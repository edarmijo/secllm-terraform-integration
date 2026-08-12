resource "aws_cloudfront_distribution" "netflix_com" {
  origin {
    domain_name = aws_s3_bucket.video_content.domain_name
    origin_access_control_id = aws_cloudfront_origin_access_identity.video_content.id
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
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_zone" "netflix_com" {
  name = "netflix.com."
}

resource "aws_route53_record" "s3_video_content_origin" {
  zone_id = aws_route53_zone.netflix_com.id
  name    = "s3-video-content-origin"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.netflix_com.domain_name
    zone_id                = aws_route53_zone.netflix_com.id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "netflix_com" {
  zone_id = aws_route53_zone.netflix_com.id
  name    = "netflix.com."
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.netflix_com.domain_name
    zone_id                = aws_route53_zone.netflix_com.id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_identity" "video_content" {
  name = "s3-video-content-origin"
}