resource "aws_lightsail_instance" "example" {
  name            = "example- lightsail-instance"
  availability_zone = "us-east-1a"
  blueprint_id    = "blueprint-id"

  # Add any additional configuration options as needed
}