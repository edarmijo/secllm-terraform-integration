provider "aws" {
  region = "us-east-1"
}

resource "aws_lb_gateway" "example" {
  name = "example-lb"
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb_gateway.example.arn
  port = 80
  protocol = "HTTP"
}