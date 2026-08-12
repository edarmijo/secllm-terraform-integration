resource "lightsail_instance" "example" {
  name            = "example- lightsail-instance"
  region          = "us-east-1"
  availability_zone = "us-east-1a"

  blueprint_id    = "Lightsail- Ubuntu 20.04 LTS"
  bundle_id       = "micro_2_0"

  ssh_key_name    = "example-ssh-key"

  tags = {
    Name = "example-lightsail-instance"
  }
}