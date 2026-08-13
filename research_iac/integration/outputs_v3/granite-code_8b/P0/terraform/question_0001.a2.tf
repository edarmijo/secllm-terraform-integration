resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_zone_association" "example" {
  zone_id = aws_route53_zone.example.id
  venue_id = aws_venue.example.id
}