resource "aws_lightsail_instance" "example" {
  name            = "example- lightsail-instance"
  availability_zone = "us-east-1a"
  blueprint_id    = "string" # replace with actual blueprint ID
  bundle_id       = "string" # replace with actual bundle ID

  region = "us-east-1"

  ssh_key_name = "example-ssh-key" # replace with actual SSH key name

  tags = {
    Name = "example-lightsail-instance"
  }
}