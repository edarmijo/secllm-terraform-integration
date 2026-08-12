resource "aws_subnet" "example1" {
  availability_zone = "us-west-2a"
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "example-subnet1"
  }
}

resource "aws_subnet" "example2" {
  availability_zone = "us-west-2b"
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "example-subnet2"
  }
}

resource "aws_subnet_group" "neptune_subnets" {
  name       = "neptune-subnets"
  subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]

  tags = {
    Name = "neptune-subnets"
  }
}