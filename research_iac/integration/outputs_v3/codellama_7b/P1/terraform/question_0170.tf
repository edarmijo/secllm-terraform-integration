resource "aws_dax_subnet_group" "example" {
  name       = "example-dax-subnet-group"
  subnet_ids = [aws_subnet.example.id]
}

resource "aws_subnet" "example" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.example.id
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}