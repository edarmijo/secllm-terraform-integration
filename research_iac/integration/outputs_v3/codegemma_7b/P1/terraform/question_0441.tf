provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc_egress_only_internet_gateway" "egress_gateway" {
  vpc_id = var.vpc_id

  ipv6_enabled = true
}