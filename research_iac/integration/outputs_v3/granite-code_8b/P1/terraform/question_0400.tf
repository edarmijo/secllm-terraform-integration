resource "aws_internet_gateway" "example" {
  tags = {
    Name = "example-igw"
  }
}

resource "aws_route_table" "public" {
  tags = {
    Name = "example-rt"
  }

  route {
    gateway_id = aws_internet_gateway.example.id

    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_elb" "example" {
  name            = "example-elb"
  internal        = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.public1.id,
    aws_subnet.public2.id,
  ]

  security_groups = [
    aws_security_group.allow_http.id,
  ]

  tags = {
    Name = "example-elb"
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow-http"
  description = "Allows HTTP traffic to the ELB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-http"
  }
}