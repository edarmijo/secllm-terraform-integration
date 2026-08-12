provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "lightsail_resource_access" {
  name        = "LightsailResourceAccessRole"
  description = "Allows Lightsail to access the S3 Bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lightsail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lightsail_resource_access" {
  role       = aws_iam_role.lightsail_resource_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLightsailServiceRolePolicy"
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
}

resource "aws_lightsail_service_linked_role_association" "example" {
  service_name = "s3.amazonaws.com"
  role_arn     = aws_iam_role.lightsail_resource_access.arn
}