resource "aws_egress_only_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-egress-only-igw"
  }
}