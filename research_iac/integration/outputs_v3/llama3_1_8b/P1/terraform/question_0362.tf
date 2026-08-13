provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "lightsail_db_password" {
  name = "LightsailDBPassword"
}

resource "aws_lightsail_instance" "this" {
  name              = "wordpress-lightsail-instance"
  blueprint_id      = "wordpress_4_0"
  bundle_id         = "nano_1_0"
  user_data         = <<EOF
#!/bin/bash
echo "LightsailDBPassword: $(data.aws_secretsmanager_secret_version.lightsail_db_password.secret_string)" > /etc/secret.txt
EOF
}

resource "aws_lightsail_instance_attachment" "this" {
  instance_name = aws_lightsail_instance.this.name
  ip_address    = aws_lightsail_static_ip_attachment.this.ip_address
}

resource "aws_lightsail_static_ip_attachment" "this" {
  instance_name = aws_lightsail_instance.this.name
}

data "aws_secretsmanager_secret_version" "lightsail_db_password" {
  secret_id = data.aws_secretsmanager_secret.lightsail_db_password.id
}

resource "aws_lightsail_database" "this" {
  name     = "wordpress-lightsail-database"
  username = "root"
  password = data.aws_secretsmanager_secret_version.lightsail_db_password.secret_string
}

resource "aws_lightsail_static_ip_attachment" "this" {
  instance_name = aws_lightsail_instance.this.name

  lifecycle {
    ignore_changes = [ip_address]
  }
}