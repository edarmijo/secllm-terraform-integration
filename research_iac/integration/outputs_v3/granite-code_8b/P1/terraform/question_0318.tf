# Configure the provider
provider "aws" {
  region = var.region
}

# Create an IAM role for the CloudFront origin access control
resource "aws_iam_role" "origin_access_control_role" {
  name = "origin-access-control-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  inline_policy = {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Resource" : ["*"],
        "Action" : [
          "s3:GetObject"
        ]
      }
    ]
  }
}

# Create an origin access control for CloudFront
resource "aws_cloudfront_origin_access_control" "example" {
  origin_access_control_name = "example-oac"

  signed_headers = [
    "host",
    "date"
  ]

  description = "Example OAC"
}

# Create a CloudFront distribution
resource "aws_cloudfront_distribution" "example" {
  origin {
    domain_name = "example.com"
    origin_id   = "example-origin"

    custom_origin_config {
      http_port               = 80
      https_port              = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols    = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_cloudfront_distribution.example.origin[0].origin_id

    viewer_protocol_policy = "redirect-to-https"

    lambda_function_ associations {
      event_type     = "viewer-request"
      lambda_arn     = "arn:aws:lambda:us-east-1:123456789012:function:example-function"
    }
  }

  restrictions {
    geo_ restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Create a Route53 zone
resource "aws_route53_zone" "example" {
  name = "example.com"
}

# Create an S3 bucket for the video content
resource "aws_s3_bucket" "video-content" {
  bucket = "video-content-bucket"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}