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
    target_bucket = aws_s3_bucket.video_bucket_logging.id
    target_prefix = "logs/"
  }
}

resource "aws_s3_bucket_logging" "video_bucket_logging" {
  bucket        = aws_s3_bucket.video_bucket.id
  destination_bucket = aws_s3_bucket.video_bucket.id // changed to use the same bucket for logging
}

resource "aws_iam_role" "cloudfront_origin_access_identity" {
  name               = "CloudFrontOriginAccessIdentityRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "cloudfront_origin_access_identity_policy" {
  name   = "CloudFrontOriginAccessIdentityPolicy"
  role   = aws_iam_role.cloudfront_origin_access_identity.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:GetObject"
        Effect = "Allow"
        Resource = "${aws_s3_bucket.video_bucket.arn}/*"
      },
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin Access Identity for CloudFront Distribution"
}

resource "aws_iam_role_policy_attachment" "cloudfront_origin_access_identity_attach" {
  role       = aws_iam_role.cloudfront_origin_access_identity.id
  policy_arn = aws_iam_role_policy.cloudfront_origin_access_identity_policy.arn
}

resource "aws_cloudfront_distribution" "video_distribution" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = "${aws_s3_bucket.video_bucket.bucket_regional_domain_name}"
    origin_id   = aws_s3_bucket.video_bucket.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.video_bucket.id

    forwarded_values {
      query_string = false
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = ""
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_zone" "video_streaming_site_domain" {
  name = "my-video-streaming-site.com."
}

resource "aws_route53_record" "video_streaming_site_alias" {
  zone_id = aws_route53_zone.video_streaming_site_domain.zone_id
  name    = aws_cloudfront_distribution.video_distribution.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.video_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.video_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}