resource "aws_lightsail_bucket" "example" {
  name = "example-bucket"
  region = "us-east-1"

  bundle_id = "micro"
}