provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "primary" {
  name = "example.com."
}

resource "aws_elb" "main" {
  name            = "example-elb"
  subnets         = [aws_subnet.main.id]
  security_groups = [aws_security_group.main.id]

  listener {
    instance_port     = 80
    lb_port           = 80
    protocol          = "http"
  }
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example.com."
  type    = "A"

  alias {
    name                   = aws_elb.main.dns_name
    zone_id                = aws_elb.main.zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group" "main" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 80"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "example-subnet"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example-vpc"
  }
}