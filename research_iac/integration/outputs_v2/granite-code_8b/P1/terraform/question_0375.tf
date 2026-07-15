resource "aws_lightsail_bucket" "example" {
  name           = "example-bucket"
  region         = "us-east-1"
  access_control = "public-read"

  tags = {
    Name        = "example-bucket"
    Environment = "production"
  }
}