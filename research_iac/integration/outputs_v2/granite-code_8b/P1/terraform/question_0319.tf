# Terraform code for creating an AWS CloudFront distribution resource with an origin argument block and associated resources

# Create the S3 bucket
resource "aws_s3_bucket" "video_content" {
  bucket = "my-video-content-bucket"
  acl    = "private"

  tags = {
    Name = "Video Content Bucket"
  }
}

# Create the CloudFront origin access control resource
resource "aws_cloudfront_origin_access_control" "s3_video_content_oac" {
  origin_access_control_id = "my-s3-video-content-oac"
  origin_access_control_origin_type = "s3"

  tags = {
    Name = "S3 Video Content Origin Access Control"
  }
}

# Create the CloudFront distribution resource
resource "aws_cloudfront_distribution" "video_content_distribution" {
  origin {
    domain_name = aws_s3_bucket.video_content.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_video_content_oac.origin_access_control_id
    origin_id = "s3_video_content_origin"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "s3_video_content_origin"
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Create the Route53 hosted zone
resource "aws_route53_zone" "netflix" {
  name = "netflix.com"
}

# Create the A record for the CloudFront distribution
resource "aws_route53_record" "video_content_distribution_a_record" {
  zone_id = aws_route53_zone.netflix.zone_id
  name    = "video-content.netflix.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_cloudfront_distribution.video_content_distribution.hosted_zone_id
    dns_name       = aws_cloudfront_distribution.video_content_distribution.domain_name
    evaluate_target_health = true
  }
}

# Create the AAAA record for the CloudFront distribution
resource "aws_route53_record" "video_content_distribution_aaaa_record" {
  zone_id = aws_route53_zone.netflix.zone_id
  name    = "video-content.netflix.com"
  type    = "AAAA"

  alias_target {
    hosted_zone_id = aws_cloudfront_distribution.video_content_distribution.hosted_zone_id
    dns_name       = aws_cloudfront_distribution.video_content_distribution.domain_name
    evaluate_target_health = true
  }
}