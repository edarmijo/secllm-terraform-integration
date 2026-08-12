provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc_peering_connection" "pike" {
  name       = "pike-peering"
  vpc_id     = aws_vpc.peer.id
  peer_vpc_id = aws_vpc.base.id

  tags = {
    Name        = "pike-peering"
    Environment = "dev"
  }
}

resource "aws_vpc" "peer" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name        = "peer-vpc"
    Environment = "dev"
  }
}

resource "aws_vpc" "base" {
  cidr_block = "10.1.0.0/24"

  tags = {
    Name        = "base-vpc"
    Environment = "dev"
  }
}