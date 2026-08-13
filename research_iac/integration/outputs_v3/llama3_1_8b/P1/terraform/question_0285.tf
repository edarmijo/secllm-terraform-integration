provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "s3_bucket_name" {
  secret_id = "s3-bucket-name"
}

locals {
  s3_bucket_name = jsondecode(data.aws_secretsmanager_secret_version.s3_bucket_name.secret_string)
}

resource "aws_s3_bucket" "static_website" {
  bucket        = local.s3_bucket_name
  acl           = "public-read"
  website {
    index_document = "index.html"
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "static_website_role" {
  name               = "static-website-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "static_website_policy" {
  name   = "static-website-policy"
  role   = aws_iam_role.static_website_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.static_website.arn
      }
    ]
  })
}

resource "aws_security_group" "static_website_sg" {
  name        = "static-website-sg"
  description = "Security group for static website"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "static_website_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.static_website_sg.id]
  iam_instance_profile = aws_iam_instance_profile.static_website_instance_profile.name

  provisioner "local-exec" {
    command = <<EOF
      echo ${aws_s3_bucket.static_website.bucket_regional_domain_name} > index.html
    EOF
  }
}

resource "aws_iam_instance_profile" "static_website_instance_profile" {
  name = "static-website-instance-profile"
  role = aws_iam_role.static_website_role.name

  provisioner "local-exec" {
    command = <<EOF
      echo ${aws_s3_bucket.static_website.bucket_regional_domain_name} > index.html
    EOF
  }
}