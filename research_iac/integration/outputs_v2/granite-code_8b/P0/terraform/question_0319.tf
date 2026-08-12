resource "aws_cloudfront_distribution" "example" {
  origin {
    domain_name = aws_s3_bucket.example.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.example.id
    origin_id = "s3_video_content_origin"

    default_cache_behavior {
      allowed_methods = ["GET", "HEAD"]
      cached_methods  = ["GET", "HEAD"]
      target_origin_id = "s3_video_content_origin"

      viewer_protocol_policy = "allow-all"
    }
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_zone" "example" {
  name = "netflix.com"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = "www.netflix.com"
  type    = "A"

  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI" # replace with the actual ID of your hosted zone
    dns_name       = "d1awfeuho0yti.cloudfront.net" # replace with the actual DNS name of your CloudFront distribution
  }
}

resource "aws_route53_record" "example2" {
  zone_id = aws_route53_zone.example.id
  name    = "netflix.com"
  type    = "A"

  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI" # replace with the actual ID of your hosted zone
    dns_name       = "d1awfeuho0yti.cloudfront.net" # replace with the actual DNS name of your CloudFront distribution
  }
}

resource "aws_cloudfront_origin_access_control" "example" {
  origin_access_control_origin_type = "s3"
  signing_behavior                   = "always"
  signing_protocol                    = "sigv4"
}