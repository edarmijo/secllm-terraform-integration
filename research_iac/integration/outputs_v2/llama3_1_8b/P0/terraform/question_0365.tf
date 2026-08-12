provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lightsail_instance" {
  name        = "LightsailInstanceRole"
  description = "For Lightsail instance"

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

resource "aws_iam_role_policy" "lightsail_instance" {
  name   = "LightsailInstancePolicy"
  role   = aws_iam_role.lightsail_instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "lightsail:GetInstance",
          "lightsail:GetInstanceAccessDetails",
          "lightsail:GetInstanceAccessDetailsHistory",
          "lightsail:GetInstanceAccessResult",
          "lightsail:GetInstanceAccessResults",
          "lightsail:GetInstanceAccessResultHistory",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lightsail_instance" {
  role       = aws_iam_role.lightsail_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLightsailServiceRolePolicy"
}

resource "aws_lightsail_instance" "example" {
  name              = "example-lightsail-instance"
  availability_zone = "us-west-2a"
  blueprint_id      = "ubuntu_18_04_64_bits"
  bundle_id         = "nano_1_0"

  key_name               = aws_lightsail_key_pair.example.key_pair_name
  user_data              = <<EOF
#!/bin/bash
echo "Hello, World!"
EOF

  depends_on = [aws_iam_role_policy_attachment.lightsail_instance]
}

resource "aws_lightsail_key_pair" "example" {
  name       = "example-lightsail-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}