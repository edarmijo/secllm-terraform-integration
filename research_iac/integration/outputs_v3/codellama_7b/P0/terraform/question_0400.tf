resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "gateway"
  subnets            = ["subnet-12345678"]
}