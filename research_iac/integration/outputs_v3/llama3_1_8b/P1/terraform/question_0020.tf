provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

resource "aws_route53_zone" "example" {
  name            = "example.com"
  comment         = "Managed by Terraform"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = "example.com"
  type    = "A"
  alias {
    name                   = var.domain_name
    zone_id                = var.zone_id
    evaluate_target_health = false
  }
}

resource "aws_secretsmanager_secret" "route53_credentials" {
  name        = "Route53Credentials"
  description = "Credentials for Route 53"
}

resource "aws_secretsmanager_secret_version" "route53_credentials" {
  secret_id     = aws_secretsmanager_secret.route53_credentials.id
  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
  })
}

data "aws_iam_policy_document" "route53_policy" {
  statement {
    actions = ["route53:GetChange", "route53:ListHostedZones"]
    resources = [aws_route53_zone.example.id]
  }
}

resource "aws_iam_role" "route53_role" {
  name        = "Route53Role"
  description = "Role for Route 53"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "route53_policy" {
  name   = "Route53Policy"
  role   = aws_iam_role.route53_role.id
  policy = data.aws_iam_policy_document.route53_policy.json
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 22 and 443"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.example.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install awscli -y",
    ]
  }
}