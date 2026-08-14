resource "aws_internet_gateway" "egress_gateway" {
  vpc_id = var.vpc_id

  ipv6_enabled = true
}