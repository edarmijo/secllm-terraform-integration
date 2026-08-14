provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "peer" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = true

  tags = {
    Name = "peer"
  }
}

resource "aws_vpc" "base" {
  cidr_block           = "10.1.0.0/24"
  enable_dns_hostnames = true

  tags = {
    Name = "base"
  }
}

resource "aws_vpc_peering_connection" "pike" {
  peer_vpc_id            = aws_vpc.peer.id
  peer_region             = "us-east-1"
  peer_owner_id           = "123456789012" # Replace with your AWS account ID
  auto_accept             = true
  allow_classic_link_to_remote_vpc = false
  allow_vgw_connect       = false
  tags                    = {
    pike = "permissions"
  }
}