provider "aws" {
  region = var.region
}

resource "aws_lb_gateway" "example" {
  name = "example-lb"
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb_gateway.example.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

resource "aws_lb_target_group" "example" {
  name = "example-tg"
  port = 80
  protocol = "HTTP"

  target {
    id = aws_instance.example.id
    port = 80
  }
}

resource "aws_instance" "example" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.example.id
}

resource "aws_subnet" "example" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.example.id
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}