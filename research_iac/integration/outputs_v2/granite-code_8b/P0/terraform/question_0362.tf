provider "aws" {
  region = var.region
}

resource "aws_lightsail_blueprint" "wordpress" {
  blueprint_id = "WordPress"
}

resource "aws_lightsail_instance" "wordpresstest" {
  name           = "wordpresstest"
  blueprint_id   = aws_lightsail_blueprint.wordpress.id
  bundle_id      = "large_2_0"
  region         = var.region

  # Add any additional configuration options as needed
}