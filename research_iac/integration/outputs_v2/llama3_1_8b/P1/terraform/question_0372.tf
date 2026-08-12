provider "aws" {
  region = var.region
}

data "aws_region" "current" {}

resource "aws_secretsmanager_secret" "lightsail_disk_password" {
  name        = "${var.project_name}-lightsail-disk-password"
  description = "Password for Lightsail Disk"
}

resource "aws_secretsmanager_secret_version" "lightsail_disk_password" {
  secret_id     = aws_secretsmanager_secret.lightsail_disk_password.id
  secret_string = var.lightsail_disk_password
}

data "aws_iam_policy_document" "lightsail_instance_role_policy" {
  statement {
    actions = [
      "lightsail:GetInstance",
      "lightsail:CreateDiskAttachment",
      "lightsail:AttachDisk"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lightsail_instance_role" {
  name               = "${var.project_name}-lightsail-instance-role"
  description        = "Role for Lightsail Instance"
  assume_role_policy = data.aws_iam_policy_document.lightsail_instance_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lightsail_instance_role_attach" {
  role       = aws_iam_role.lightsail_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLightsailFullAccess"
}

data "aws_iam_policy_document" "lightsail_disk_role_policy" {
  statement {
    actions = [
      "lightsail:GetDisk",
      "lightsail:CreateDiskAttachment",
      "lightsail:AttachDisk"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lightsail_disk_role" {
  name               = "${var.project_name}-lightsail-disk-role"
  description        = "Role for Lightsail Disk"
  assume_role_policy = data.aws_iam_policy_document.lightsail_disk_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lightsail_disk_role_attach" {
  role       = aws_iam_role.lightsail_disk_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLightsailFullAccess"
}

resource "aws_lightsail_instance" "example" {
  name              = "${var.project_name}-lightsail-instance"
  availability_zone = var.availability_zone
  blueprint_id      = "ubuntu_18_04_64_bits"
  bundle_id         = "micro_2_0"
  depends_on        = [aws_iam_role_policy_attachment.lightsail_instance_role_attach]
}

resource "aws_lightsail_disk" "example" {
  name              = "${var.project_name}-lightsail-disk"
  size_in_gb        = 20
  availability_zone = var.availability_zone
  depends_on        = [aws_secretsmanager_secret_version.lightsail_disk_password]
}

resource "aws_lightsail_disk_attachment" "example" {
  instance_name = aws_lightsail_instance.example.name
  disk_name      = aws_lightsail_disk.example.name
}