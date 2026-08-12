provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "primary.com"
}

resource "aws_route53_geo_location" "us" {
  continent_code = "US"
}

resource "aws_route53_geo_location" "eu" {
  continent_code = "EU"
}

resource "aws_route53_traffic_policy" "routing_policy" {
  name = "routing_policy"

  rule {
    type = "geo"
    geo_location_name = "us"
    location_constraint {
      continent_code = "US"
    }
    action {
      type = "weighted_target"
      target {
        type = "endpoint"
        endpoint_url = "us-endpoint.com"
        weight = 1
      }
    }
  }

  rule {
    type = "geo"
    geo_location_name = "eu"
    location_constraint {
      continent_code = "EU"
    }
    action {
      type = "weighted_target"
      target {
        type = "endpoint"
        endpoint_url = "eu-endpoint.com"
        weight = 1
      }
    }
  }
}

resource "aws_route53_traffic_policy_attachment" "attach_routing_policy" {
  traffic_policy_id = aws_route53_traffic_policy.routing_policy.id
  hosted_zone_id = aws_route53_zone.primary.zone_id
}