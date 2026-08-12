provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudfront_distribution" "netflix_distribution" {
  enabled         = true
  aliases          = ["${var.domain_name}"]
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3_video_content_origin"
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      query_string = true
    }
  }

  origin {
    domain_name = "${var.domain_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.netflix_origin_access_control.id
    origin_id   = "s3_video_content_origin"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_200"
}

resource "aws_route53_zone" "netflix_zone" {
  name = "netflix.com"
}

resource "aws_route53_record" "netflix_distribution_record" {
  zone_id = aws_route53_zone.netflix_zone.zone_id
  name    = "${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.netflix_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.netflix_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "netflix_distribution_validation_record" {
  zone_id = aws_route53_zone.netflix_zone.zone_id
  name    = "_validation.${var.domain_name}"
  type    = "CNAME"
  alias {
    name                   = aws_cloudfront_distribution.netflix_distribution.hosted_zone_id
    zone_id                = aws_cloudfront_distribution.netflix_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_control" "netflix_origin_access_control" {
  name               = "netflix-origin-access-control"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}