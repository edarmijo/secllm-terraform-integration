provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_instance" "wordpress" {
  name              = "wordpress"
  availability_zone = "us-east-1a"
  blueprint_id      = "wordpress"
  bundle_id         = "micro_2_0"
  key_pair_name     = "my_key_pair"
  user_data         = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install -y lamp-mariadb10.2-php7.2
systemctl start httpd
systemctl enable httpd
systemctl start mariadb
systemctl enable mariadb
mysqladmin -u root password 'my_password'
EOF
}

resource "aws_lightsail_static_ip" "wordpress" {
  name = "wordpress-static-ip"
}

resource "aws_lightsail_static_ip_attachment" "wordpress" {
  static_ip_name   = aws_lightsail_static_ip.wordpress.name
  instance_name    = aws_lightsail_instance.wordpress.name
}