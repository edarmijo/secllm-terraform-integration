provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "cloudfront_origin_access_control" {
  name = "cloudfront_origin_access_control"

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

resource "aws_cloudfront_origin_access_control" "video_content" {
  name = "video_content"
  iam_role_id = aws_iam_role.cloudfront_origin_access_control.id
}

resource "aws_cloudfront_distribution" "video_streaming" {
  origin {
    domain_name = aws_s3_bucket.video_content.bucket_domain_name
    origin_id = "video_content"
    origin_access_control_id = aws_cloudfront_origin_access_control.video_content.id
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    default_ttl = 86400
    max_ttl = 31536000
  }
}

resource "aws_route53_zone" "video_streaming" {
  name = "video.example.com"
}

resource "aws_s3_record" "video_streaming" {
  zone_id = aws_route53_zone.video_streaming.zone_id
  name = "video.example.com"
  type = "A"
  alias {
    name = aws_cloudfront_distribution.video_streaming.domain_name
    zone_id = "Z2FDTNDATAQYW2"
  }
}