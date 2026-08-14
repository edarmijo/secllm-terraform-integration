variable "aws_region" {
  type        = string
}

variable "video_streaming_bucket_name" {
  type        = string
}

provider "aws" {
  region = var.aws_region
}

# Create an IAM role for CloudFront to access S3 bucket
resource "aws_iam_role" "cloudfront_s3_access" {
  name        = "CloudFrontS3AccessRole"
  description = "Allow CloudFront to access S3 bucket"

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
  description = "Allow CloudFront to access S3 bucket"

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
        Resource = aws_s3_bucket.video_streaming.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudfront_s3_access_attach" {
  role       = aws_iam_role.cloudfront_s3_access.name
  policy_arn = aws_iam_policy.cloudfront_s3_access_policy.arn
}

# Create an IAM role for Route53 to access S3 bucket
resource "aws_iam_role" "route53_s3_access" {
  name        = "Route53S3AccessRole"
  description = "Allow Route53 to access S3 bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "route53_s3_access_policy" {
  name        = "Route53S3AccessPolicy"
  description = "Allow Route53 to access S3 bucket"

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
        Resource = aws_s3_bucket.video_streaming.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "route53_s3_access_attach" {
  role       = aws_iam_role.route53_s3_access.name
  policy_arn = aws_iam_policy.route53_s3_access_policy.arn
}

# Create an S3 bucket for video streaming
resource "aws_s3_bucket" "video_streaming" {
  bucket        = var.video_streaming_bucket_name
  acl           = "private"
  versioning    = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 365
    }
  }
}

# Create an S3 bucket policy for video streaming
resource "aws_s3_bucket_policy" "video_streaming_policy" {
  bucket = aws_s3_bucket.video_streaming.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.video_streaming.arn}/*"
      }
    ]
  })
}

# Create an AWS CloudFront distribution
resource "aws_cloudfront_distribution" "video_streaming" {
  enabled         = true
  is_ipv6_enabled = true

  aliases = [var.video_streaming_bucket_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.video_streaming_bucket_name

    forwarded_values {
      query_string = false
    }

    viewer_protocol_policy = "https-only"
  }

  origin {
    domain_name = aws_s3_bucket.video_streaming.website_endpoint
    origin_id   = var.video_streaming_bucket_name

    custom_header {
      name  = "X-Amz-Date"
      value = "${strftime("%Y%m%dT%H%M%SZ", timestamp())}"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.video_streaming.arn
    ssl_support_method  = "sni-only"
  }
}

# Create an AWS Route53 record set for video streaming
resource "aws_route53_record" "video_streaming" {
  zone_id = aws_route53_zone.video_streaming.zone_id
  name    = var.video_streaming_bucket_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.video_streaming.domain_name
    zone_id                = aws_cloudfront_distribution.video_streaming.hosted_zone_id
    evaluate_target_health = false
  }
}

# Create an AWS ACM certificate for video streaming
resource "aws_acm_certificate" "video_streaming" {
  domain_name       = var.video_streaming_bucket_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  options {
    ssl_support_method = "sni-only"
  }
}

# Create an AWS Route53 zone for video streaming
resource "aws_route53_zone" "video_streaming" {
  name = var.video_streaming_bucket_name
}