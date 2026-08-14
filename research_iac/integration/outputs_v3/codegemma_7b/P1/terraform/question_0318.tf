provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudfront_origin_access_control" "video_origin_access_control" {
  comment = "Origin access control for video streaming"
  signing_algorithm = "AWS4-HMAC-SHA256"
  origin_access_control_policy {
    statement {
      action = "s3:GetObject"
      principal {
        canonical_user = "YOUR_CANONICAL_USER_ID"
      }
      resource = "YOUR_S3_BUCKET_ARN/*"
    }
  }
}

resource "aws_cloudfront_distribution" "video_distribution" {
  origin {
    domain_name = aws_s3_bucket.video_bucket.bucket_domain_name
    origin_id = aws_cloudfront_origin_access_control.video_origin_access_control.id
    origin_access_control_origin_path = "/"
  }
  default_root_object = "index.html"
  enabled = true
  price_class = "PriceClass_All"
  viewer_certificate {
    acm_certificate_arn = "YOUR_ACM_CERTIFICATE_ARN"
  }
}

resource "aws_route53_zone" "video_zone" {
  name = "YOUR_DOMAIN_NAME"
}

resource "aws_s3_record" "video_record" {
  zone_id = aws_route53_zone.video_zone.zone_id
  name = "YOUR_DOMAIN_NAME"
  type = "A"
  alias {
    name = aws_cloudfront_distribution.video_distribution.domain_name
    zone_id = "Z2FDTNDATAQYW2"
  }
}