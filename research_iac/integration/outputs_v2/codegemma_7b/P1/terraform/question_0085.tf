provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}

resource "aws_route53_geolocation_routing_policy" "geolocation_policy" {
  name = "geolocation_policy"

  location {
    continent = "US"
    endpoint = "us-east-1.compute.amazonaws.com"
  }

  location {
    continent = "EU"
    endpoint = "eu-west-1.compute.amazonaws.com"
  }
}

resource "aws_route53_record" "geolocation_record" {
  name = "example.com"
  type = "A"
  alias {
    name = aws_route53_geolocation_routing_policy.geolocation_policy.name
    zone_id = aws_route53_geolocation_routing_policy.geolocation_policy.zone_id
  }
}