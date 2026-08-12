resource "aws_route53_zone_association" "example" {
  zone_id = aws_route53_zone.my_zone.zone_id
  vpc_id = aws_vpc.my_vpc.id
  delegation_set_id = aws_route53_delegation_set.my_delegation_set.id
}