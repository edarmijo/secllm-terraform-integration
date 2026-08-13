provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "wordpress" {
  name              = "wordpress"
  availability_zone = "us-east-1a"
  blueprint_id      = "wordpress_lemp"
  bundle_id         = "micro_2_0"
  key_pair_name     = "my_key_pair"
}

resource "aws_lightsail_static_ip" "wordpress" {
  name = "wordpress-static-ip"
}

resource "aws_lightsail_instance_attachment" "wordpress" {
  instance_name   = aws_lightsail_instance.wordpress.name
  static_ip_name  = aws_lightsail_static_ip.wordpress.name
}