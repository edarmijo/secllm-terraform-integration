# Configure the AWS provider
provider "aws" {
  region = var.region
}

# Create an IAM role for CloudFront to assume
resource "aws_iam_role" "cloud_front_assume_role" {
  name               = "CloudFrontAssumeRole"
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
}

# Create an IAM role policy for CloudFront to assume the role
resource "aws_iam_role_policy" "cloud_front_assume_role_policy" {
  name   = "CloudFrontAssumeRolePolicy"
  role   = aws_iam_role.cloud_front_assume_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": "s3:GetObject"
    }
  ]
}
EOF
}

# Create a CloudFront distribution
resource "aws_cloudfront_distribution" "video_streaming_site" {
  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id

    custom_origin_config {
      http_port               = 80
      https_port              = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols    = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object

  price_class         = "PriceClass_All"
  viewer_protocol_policy = "redirect-to-https"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

 ViewerCertificate {
    cloudfront_default_certificate = true
  }

  origin_access_identity {
    cloudfront_origin_access_identity_id = aws_cloudfront_origin_access_identity.video_streaming_site.id
    path                                 = var.origin_path
  }
}

# Create a Route53 zone
resource "aws_route53_zone" "video_streaming_site" {
  name = var.domain_name
}

# Create an S3 bucket for the video content
resource "aws_s3_bucket" "video_content" {
  bucket = var.video_content_bucket_name

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}