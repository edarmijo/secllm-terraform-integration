provider "aws" {
  region = var.region
}

variable "wordpress_username" {
  type = string
}

variable "wordpress_password" {
  type = string
}

resource "aws_lightsail_instance" "wordpress" {
  name = "wordpress-instance"
  blueprint_id = "wordpress"
  availability_zone = var.availability_zone
  tags = {
    Name = "WordPress Instance"
  }
}

resource "aws_lightsail_static_ip" "wordpress_static_ip" {
  name = "wordpress-static-ip"
}

resource "aws_lightsail_domain" "wordpress_domain" {
  name = "wordpress.example.com"
}

resource "aws_lightsail_domain_entry" "wordpress_domain_entry" {
  domain_name = aws_lightsail_domain.wordpress_domain.name
  name = "@,www"
  type = "A"
  target = aws_lightsail_static_ip.wordpress_static_ip.ip_address
}

resource "aws_lightsail_certificate" "wordpress_certificate" {
  domain_name = aws_lightsail_domain.wordpress_domain.name
}

resource "aws_lightsail_lb_target_group" "wordpress_target_group" {
  name = "wordpress-target-group"
  protocol = "HTTP"
  port = 80
  health_check {
    path = "/"
  }
}

resource "aws_lightsail_lb" "wordpress_lb" {
  name = "wordpress-lb"
  load_balancer_type = "application"
  listener {
    port = 80
    protocol = "HTTP"
    ssl_certificate_arn = aws_lightsail_certificate.wordpress_certificate.arn
    target_group_arn = aws_lightsail_lb_target_group.wordpress_target_group.arn
  }
}

resource "aws_lightsail_lb_attachment" "wordpress_lb_attachment" {
  load_balancer_name = aws_lightsail_lb.wordpress_lb.name
  instance_name = aws_lightsail_instance.wordpress.name
}

resource "aws_secretsmanager_secret" "wordpress_secret" {
  name = "wordpress-secret"
  secret_string = jsonencode({
    username = var.wordpress_username
    password = var.wordpress_password
  })
}

resource "aws_lightsail_instance_public_key" "wordpress_public_key" {
  name = "wordpress-public-key"
  key_body = var.public_key
}

resource "aws_lightsail_instance_private_key" "wordpress_private_key" {
  name = "wordpress-private-key"
}

resource "aws_lightsail_instance_user_data" "wordpress_user_data" {
  name = "wordpress-user-data"
  user_data = file("wordpress_user_data.sh")
}

resource "aws_lightsail_instance_metadata_options" "wordpress_metadata_options" {
  name = "wordpress-metadata-options"
  http_tokens = "required"
}