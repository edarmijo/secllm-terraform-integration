provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_traffic_policy" "example" {
  name = "example-traffic-policy"

  statement {
    type = "GeoLocation"
    value = {
      continent = "NA"
    }
  }

  statement {
    type = "GeoLocation"
    value = {
      country = "US"
    }
  }

  statement {
    type = "GeoLocation"
    value = {
      region = "CA"
    }
  }
}

resource "aws_route53_traffic_policy_attachment" "example" {
  traffic_policy_id = aws_route53_traffic_policy.example.id
  hosted_zone_id = "YOUR_HOSTED_ZONE_ID"
}