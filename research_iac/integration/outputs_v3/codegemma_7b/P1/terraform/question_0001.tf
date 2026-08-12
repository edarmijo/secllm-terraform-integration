resource "aws_route53_zone_association" "example" {
  zone_id = aws_route53_zone.example.zone_id
  vpc_id = aws_vpc.example.id
  delegation_set_id = aws_route53_delegation_set.example.id
}