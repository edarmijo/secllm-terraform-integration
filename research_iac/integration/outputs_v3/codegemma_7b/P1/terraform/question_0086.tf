provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_traffic_policy" "example" {
  name = "example-traffic-policy"

  statement {
    type = "geo"
    geo_location {
      continent_code = "NA"
    }
    weight = 50
  }

  statement {
    type = "geo"
    geo_location {
      country_code = "US"
    }
    weight = 50
  }
}

resource "aws_route53_traffic_policy_attachment" "example" {
  traffic_policy_id = aws_route53_traffic_policy.example.id
  hosted_zone_id = "YOUR_HOSTED_ZONE_ID"
}