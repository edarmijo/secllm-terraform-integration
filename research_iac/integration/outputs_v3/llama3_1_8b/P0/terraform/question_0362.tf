provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lightsail_instance_role" {
  name        = "LightsailInstanceRole"
  description = "For AWS Lightsail instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lightsail.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lightsail_instance_attach" {
  role       = aws_iam_role.lightsail_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLightsailInstanceRolePolicy"
}

resource "aws_lightsail_container_service" "wordpress" {
  name   = "WordPress"
  instance_name = "lightsail-instance"

  container_definitions = jsonencode([
    {
      name        = "wordpress"
      image       = "wordpress:latest"
      cpu          = 10
      essential   = true
      portMappings = [
        {
          hostPort = 80
          protocol = "tcp"
          containerPort = 80
        },
      ]
    }
  ])
}

resource "aws_lightsail_instance" "example" {
  name              = "lightsail-instance"
  blueprint_id      = "wordpress_3_8_2"
  bundle_id         = "micro_1_0"
  user_data         = base64encode(templatefile("${path.module}/user-data.sh", {}))
}

resource "aws_lightsail_static_ip_attachment" "example" {
  instance_name = aws_lightsail_instance.example.name
}