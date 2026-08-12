provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_cloudfront_distribution" "netflix_video_content" {
  enabled         = true
  aliases          = [var.netflix_domain_name]
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_cloudfront_origin_access_control.s3_video_content.id

    forwarded_values {
      query_string = false
    }

    viewer_protocol_policy = "allow-all"
  }

  origin {
    domain_name = var.s3_bucket_domain_name
    origin_id   = "s3_video_content_origin"

    custom_header {
      name  = "Host"
      value = var.s3_bucket_domain_name
    }
  }

  origins {
    origin_id   = aws_cloudfront_origin_access_control.s3_video_content.id
    domain_name = var.s3_bucket_domain_name
    custom_header {
      name  = "Host"
      value = var.s3_bucket_domain_name
    }
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

resource "aws_route53_zone" "netflix" {
  name = var.netflix_domain_name
}

resource "aws_route53_record" "netflix_video_content" {
  zone_id = aws_route53_zone.netflix.zone_id
  name    = var.netflix_domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.netflix_video_content.domain_name
    zone_id                = aws_cloudfront_distribution.netflix_video_content.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "netflix_video_content_alias" {
  zone_id = aws_route53_zone.netflix.zone_id
  name    = "*.${var.netflix_domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.netflix_video_content.domain_name
    zone_id                = aws_cloudfront_distribution.netflix_video_content.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_control" "s3_video_content" {
  name               = var.netflix_domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior     = "always"
  signing_protocol     = "sigv4"
}