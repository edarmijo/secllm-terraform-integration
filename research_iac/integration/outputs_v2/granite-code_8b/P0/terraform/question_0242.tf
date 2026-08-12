resource "aws_subnet" "example1" {
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "example-subnet1"
  }
}

resource "aws_subnet" "example2" {
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "example-subnet2"
  }
}

resource "aws_db_subnet_group" "example" {
  name       = "example-subnet-group"
  subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]

  tags = {
    Name = "example-subnet-group"
  }
}