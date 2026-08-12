provider "aws" {
  region = var.region
}

# Create an IAM role for CloudFront to access S3
resource "aws_iam_role" "cloudfront_s3_access" {
  name        = "CloudFrontS3AccessRole"
  description = "Allows CloudFront to access S3"

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

resource "aws_iam_policy" "cloudfront_s3_access_policy" {
  name        = "CloudFrontS3AccessPolicy"
  description = "Allows CloudFront to access S3"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.video_bucket.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudfront_s3_access_attach" {
  role       = aws_iam_role.cloudfront_s3_access.name
  policy_arn = aws_iam_policy.cloudfront_s3_access_policy.arn
}

# Create an IAM role for S3 to access CloudFront
resource "aws_iam_role" "s3_cloudfront_access" {
  name        = "S3CloudFrontAccessRole"
  description = "Allows S3 to access CloudFront"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_cloudfront_access_policy" {
  name        = "S3CloudFrontAccessPolicy"
  description = "Allows S3 to access CloudFront"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:UpdateDistribution"
        ]
        Effect   = "Allow"
        Resource = aws_cloudfront_distribution.video_distribution.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_cloudfront_access_attach" {
  role       = aws_iam_role.s3_cloudfront_access.name
  policy_arn = aws_iam_policy.s3_cloudfront_access_policy.arn
}

# Create an S3 bucket for video storage
resource "aws_s3_bucket" "video_bucket" {
  bucket = var.video_bucket_name

  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create a CloudFront distribution for video streaming
resource "aws_cloudfront_distribution" "video_distribution" {
  origin {
    domain_name = aws_s3_bucket.video_bucket.bucket_regional_domain_name
    origin_id   = var.video_bucket_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.video_bucket_name

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

  tags = {
    Name = var.video_bucket_name
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.video_cert.certificate_arn
    ssl_support_method  = "sni-only"
  }
}

# Create an ACM certificate for the CloudFront distribution
resource "aws_acm_certificate" "video_cert" {
  domain_name       = var.video_bucket_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "video_cert" {
  certificate_arn         = aws_acm_certificate.video_cert.arn
  validation_record_fqdns = [aws_route53_record.validation_record.fqdn]
}

# Create a Route 53 record for the CloudFront distribution
resource "aws_route53_record" "validation_record" {
  zone_id = aws_route53_zone.video_zone.id
  name    = "_acm-validation-${aws_acm_certificate.video_cert.domain_name}"
  type    = "CNAME"
  ttl     = "60"

  records = [aws_acm_certificate_validation.video_cert.validation_record.0.resource_record_value]
}

resource "aws_route53_zone" "video_zone" {
  name = var.video_bucket_name
}