provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "video_bucket" {
  bucket = "my-video-streaming-site-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "video_bucket" {
  bucket = aws_s3_bucket.video_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

resource "aws_iam_role" "cloudfront_distribution" {
  name        = "my-cloudfront-distribution-role"
  description = "Role for CloudFront distribution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudfront_distribution" {
  name   = "my-cloudfront-distribution-policy"
  role   = aws_iam_role.cloudfront_distribution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.video_bucket.arn
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "video_distribution" {
  enabled         = true
  is_ipv6_enabled = true

  aliases = ["my-video-streaming-site.com"]

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.video_bucket.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.video_bucket.website_endpoint
    origin_id   = aws_s3_bucket.video_bucket.id

    custom_origin_config {
      http_port  = 80
      https_port = 443

      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2-TLSv1.1"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.video_cert.certificate_arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_zone" "video_zone" {
  name = "my-video-streaming-site.com"
}

resource "aws_route53_record" "video_alias" {
  zone_id = aws_route53_zone.video_zone.zone_id
  name    = aws_cloudfront_distribution.video_distribution.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.video_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.video_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "video_cert" {
  domain_name       = aws_route53_zone.video_zone.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket_logging" "video_bucket_logging" {
  bucket        = aws_s3_bucket.video_bucket.id
  target_bucket = aws_s3_bucket.video_bucket.id

  depends_on = [
    aws_s3_bucket.video_bucket,
  ]
}