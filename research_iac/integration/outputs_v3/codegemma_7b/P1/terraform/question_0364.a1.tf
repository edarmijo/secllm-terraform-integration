provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "dualstack_instance" {
  name = "dualstack-instance"

  # Specify the Lightsail blueprint ID
  blueprint_id = "your_blueprint_id"

  # Specify the Lightsail bundle ID
  bundle_id = "your_bundle_id"

  availability_zone = "us-east-1a"

  tags = {
    Name = "Dualstack Instance"
  }
}