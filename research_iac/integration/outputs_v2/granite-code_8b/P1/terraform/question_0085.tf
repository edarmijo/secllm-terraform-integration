# Create a primary Route 53 zone for the US continent
resource "aws_route53_zone" "us_primary" {
  name = "example.com."
}

# Create a primary Route 53 zone for the EU continent
resource "aws_route53_zone" "eu_primary" {
  name = "example.com."
}

# Create a routing policy that utilizes a user's location to route them to the nearest endpoint of a route 53 zone
resource "aws_route53_health_check" "example_health_check" {
  # Health check configuration
}

resource "aws_route53_record" "example_record" {
  zone_id = aws_route53_zone.us_primary.id
  name    = "example.com"
  type    = "A"

  alias_target {
    hosted_zone_id = aws_elb.example.id
    dns_name       = aws_elb.example.dns_name
    evaluate_target_health = true
  }
}