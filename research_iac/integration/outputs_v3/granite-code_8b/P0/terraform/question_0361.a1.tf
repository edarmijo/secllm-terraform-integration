provider "aws" {
  region = "us-east-1"
}

resource "lightsail_instance" "example" {
  name            = "example-lightsail-instance"
  blueprint_id    = "Lightsail Blueprint | General Purpose GPU v1"
  bundle_id       = "gpu-large-2gb"

  additional_ip_address_count = 1

  tags = {
    Name = "example-lightsail-instance"
  }
}