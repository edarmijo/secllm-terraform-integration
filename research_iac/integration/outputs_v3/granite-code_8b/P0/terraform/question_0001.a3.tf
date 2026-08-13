resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_zone_association" "example" {
  zone_id = aws_route53_zone.example.id
  vpc_id = aws_vpc.example.id
}