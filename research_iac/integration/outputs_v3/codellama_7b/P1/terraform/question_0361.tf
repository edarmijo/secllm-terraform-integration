provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "example" {
  name              = "example"
  blueprint_id      = "default"
  bundle_id         = "nano"
  availability_zone = "us-east-1a"
  key_pair_name     = "my-key-pair"
}