resource "aws_vpc_peering_connection" "pike" {
  peer_vpc_id     = aws_vpc.peer.id
  peer_region     = "us-east-1"
  peer_role_arn   = aws_iam_role.peer.arn
  auto_accept     = true
  tags            = { pike = "permissions" }
}