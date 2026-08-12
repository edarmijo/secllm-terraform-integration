provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "video_bucket" {
  bucket = "my-video-streaming-site-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.video_bucket_log.id
    target_prefix = "logs/"
  }
}

resource "aws_s3_bucket_public_access_block" "video_bucket_access" {
  bucket = aws_s3_bucket.video_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_distribution" "video_distribution" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.video_bucket.website_endpoint
    origin_id   = "my-video-streaming-site-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "my-video-streaming-site-origin"

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
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB"]
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.video_cert.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_s3_bucket" "video_bucket_log" {
  bucket = "my-video-streaming-site-bucket-logs"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.video_bucket.id
    target_prefix = "logs/"
  }
}

resource "aws_acm_certificate_validation" "video_cert" {
  certificate_arn = aws_acm_certificate.video_cert.arn

  validation_method = "DNS"

  validation_record {
    name    = aws_route53_record.video_cert_validation.name
    type    = "CNAME"
    alias   = true
    zone_id = aws_route53_zone.video_zone.id
  }
}

resource "aws_acm_certificate" "video_cert" {
  domain_name       = "my-video-streaming-site.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "video_cert_validation" {
  zone_id = aws_route53_zone.video_zone.id
  name    = aws_acm_certificate_validation.video_cert.validation_record[0].name
  type    = "CNAME"
  alias {
    name                   = aws_cloudfront_distribution.video_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.video_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_zone" "video_zone" {
  name = "my-video-streaming-site.com"
}