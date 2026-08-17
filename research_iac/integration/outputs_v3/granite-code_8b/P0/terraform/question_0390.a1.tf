resource "aws_lb" "test-lb-tf" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    "subnet-12345678",
    "subnet-87654321",
  ]

  security_groups = [
    "sg-12345678",
    "sg-87654321",
  ]

  deletion_protection = false
}