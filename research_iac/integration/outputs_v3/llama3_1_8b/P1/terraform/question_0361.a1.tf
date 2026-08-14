provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

variable "lightsail_api_key" {}
variable "vpc_id" {}
variable "instance_name" {}

resource "aws_secretsmanager_secret" "lightsail_api_key" {
  name        = "LightsailAPIKey"
  description = "Lightsail API Key for Terraform"
}

resource "aws_secretsmanager_secret_version" "lightsail_api_key_value" {
  secret_id     = aws_secretsmanager_secret.lightsail_api_key.id
  secret_string = var.lightsail_api_key
}

data "aws_iam_policy_document" "lightsail_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lightsail_instance_profile" {
  name               = "LightsailInstanceProfile"
  assume_role_policy = data.aws_iam_policy_document.lightsail_assume_role_policy.json
}

data "aws_iam_policy_document" "lightsail_inline_policy" {
  statement {
    actions = [
      "lightsail:GetBlueprints",
      "lightsail:GetInstances",
      "lightsail:CreateInstances"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lightsail_inline_policy" {
  name   = "LightsailInlinePolicy"
  role   = aws_iam_role.lightsail_instance_profile.id
  policy = data.aws_iam_policy_document.lightsail_inline_policy.json
}

data "aws_security_group" "default" {
  name       = "default"
  vpc_id     = var.vpc_id
}

resource "aws_security_group_rule" "lightsail_sg_rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = data.aws_security_group.default.id
  cidr_blocks       = ["0.0/0"]
}

resource "aws_lightsail_instance" "example" {
  name              = var.instance_name
  blueprint_id      = "conventional_1_0"
  bundle_id         = "micro_1_0"
  user_data         = <<EOF
#!/bin/bash

echo "Hello World!"
EOF
}