provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "base" {
  cidr_block = "10.1.0.0/24"
}

resource "aws_vpc" "peer" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_vpc_peering_connection" "pike" {
  peer_owner_id = aws_account_id
  peer_vpc_id   = aws_vpc.base.id
  vpc_id        = aws_vpc.peer.id
  tags = {
    Name = "pike"
    pike = "permissions"
  }
}