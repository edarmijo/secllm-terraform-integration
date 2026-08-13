resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "gateway"

  subnets = ["subnet-12345678", "subnet-87654321"]

  tags = {
    Environment = "production"
  }
}