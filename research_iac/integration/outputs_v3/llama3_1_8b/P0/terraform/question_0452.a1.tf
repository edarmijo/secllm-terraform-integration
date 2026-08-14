provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc_peering_connection" "pike" {
  vpc_id       = aws_vpc.peer.id
  peer_vpc_id  = aws_vpc.base.id
  peer_owner_id = data.aws_caller_identity.current.account_id

  tags = {
    Name        = "pike"
    Description = "permissions"
  }
}

resource "aws_vpc" "peer" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "peer"
  }
}

resource "aws_vpc" "base" {
  cidr_block = "10.1.0.0/24"

  tags = {
    Name = "base"
  }
}

data "aws_caller_identity" "current" {}