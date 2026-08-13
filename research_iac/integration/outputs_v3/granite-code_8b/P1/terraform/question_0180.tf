resource "aws_imeter notebook" "example" {
  name           = "example-imeter-notebook"
  role_arn       = "arn:aws:iam::123456789012:role/imeter-notebook-role"
  instance_type  = "ml.t2.medium"
  volume_size    = 50
  security_group_ids = [
    "sg-0123456789abcdef0",
    "sg-1234567890abcdef0",
  ]
  subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-1234567890abcdef0",
  ]

  tags = {
    Environment = "production"
  }
}