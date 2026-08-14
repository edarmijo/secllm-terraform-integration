# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create an IAM role for CloudFront to assume
resource "aws_iam_role" "cloudfront_role" {
  name        = "CloudFrontRole"
  description = "IAM role for CloudFront to access S3 bucket"

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

# Create an IAM policy for CloudFront to access S3 bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "IAM policy for CloudFront to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = aws_s3_bucket.video_streaming.arn
      }
    ]
  })
}

# Attach the IAM policy to the CloudFront role
resource "aws_iam_role_policy_attachment" "cloudfront_attach" {
  role       = aws_iam_role.cloudfront_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Create an S3 bucket for video streaming content
resource "aws_s3_bucket" "video_streaming" {
  bucket = "video-streaming-bucket"
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

# Create an S3 bucket policy to allow CloudFront access
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

        Condition = {
          Bool = {
            "aws:CalledVia" = ["cloudfront.amazonaws.com"]
          }
        }
      }
    ]
  })
}

# Create an AWS CloudFront origin access control
resource "aws_cloudfront_origin_access_control" "video_streaming_oac" {
  name                            = "VideoStreamingOAC"
  description                    = "Origin Access Control for Video Streaming"
  signing_behavior               = "optional"
  signing_protocol               = "sigv2"
  origin_access_control_origin_type = "s3"

}

# Create an AWS CloudFront distribution
resource "aws_cloudfront_distribution" "video_streaming_cfd" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name = aws_s3_bucket.video_streaming.bucket_regional_domain_name
    origin_id   = var.origin_id

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
    target_origin_id = var.origin_id

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
    cloudfront_default_certificate = true
  }
}

# Create an AWS Route53 zone for video streaming site
resource "aws_route53_zone" "video_streaming_zone" {
  name = "video-streaming-site.com."
}

# Create an ACM certificate for the CloudFront distribution
resource "aws_acm_certificate" "video_streaming_cert" {
  domain_name       = aws_route53_zone.video_streaming_zone.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create an S3 record for video streaming site
resource "aws_s3_bucket_website_configuration" "video_streaming_site_config" {
  bucket = aws_s3_bucket.video_streaming.id

  index_document {
    suffix = "index.html"
  }
}