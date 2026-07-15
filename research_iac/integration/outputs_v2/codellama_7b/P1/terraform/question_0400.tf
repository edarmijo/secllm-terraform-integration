resource "aws_lb" "example" {
  name               = "example-gateway-load-balancer"
  internal           = false
  load_balancer_type = "gateway"
  subnets            = ["subnet-12345678"]
}