provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "example" {
  name           = "example- lightsail-instance"
  availability_zone = "us-east-1a"
  blueprint_id    = "wordpress_latest_stable"

  # Set the instance's password
  admin_password = "MyNewPassword1234!"

  # Configure the instance's network settings
  network_ports {
    port     = 80
    protocol = "tcp"
    from_port = 80
    to_port   = 80
    cidrs    = ["0.0.0.0/0"]
  }

  # Set up the instance's storage
  disks {
    name   = "example-disk1"
    size   = 32
    attach = true
  }

  # Add additional tags to the instance
  tags = {
    Name        = "example-lightsail-instance"
    Environment = "production"
  }
}