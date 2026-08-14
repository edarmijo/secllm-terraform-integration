resource "aws_lightsail_bucket" "example" {
  name           = "example-bucket"
  region         = "us-east-1"
  bundle_id      = "micro/yearly"
  access_control = "public-read"

  tags = {
    Name        = "example-bucket"
    Environment = "production"
  }
}