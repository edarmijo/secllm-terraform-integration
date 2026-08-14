provider "aws" {
  region = var.region
}

variable "video_content_bucket_name" {}
variable "video_streaming_site_domain" {}
variable "video_streaming_site_elb_name" {}
variable "video_streaming_site_ssl_cert_arn" {}
variable "video_streaming_site_lambda_role_name" {}
variable "video_streaming_site_lambda_log_group_name" {}
variable "video_streaming_site_lambda_log_stream_name" {}

resource "aws_s3_bucket" "video_content" {
  bucket = var.video_content_bucket_name
  acl    = "public-read"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_route53_zone" "video_streaming_site" {
  name = var.video_streaming_site_domain

  tags = {
    Environment = "Production"
  }
}

resource "aws_route53_record" "video_streaming_site_alias" {
  zone_id = aws_route53_zone.video_streaming_site.zone_id
  name    = var.video_streaming_site_domain
  type    = "A"

  alias_target {
    hosted_zone_id = aws_elb.video_streaming_site.zone_id
    dns_name       = aws_elb.video_streaming_site.dns_name
    evaluate_target_health = true
  }
}

resource "aws_elb" "video_streaming_site" {
  name            = var.video_streaming_site_elb_name
  internal        = false
  load_balancer_type = "application"

  subnets = [
    aws_subnet.video_streaming_site_public_a.id,
    aws_subnet.video_streaming_site_public_b.id,
  ]

  security_groups = [
    aws_security_group.video_streaming_site_elb.id,
  ]

  listener {
    protocol           = "HTTPS"
    port               = 443
    ssl_certificate_id = var.video_streaming_site_ssl_cert_arn

    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.video_streaming_site.id
    }
  }
}

resource "aws_lb_target_group" "video_streaming_site" {
  name        = var.video_streaming_site_elb_name
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    path = "/health-check"
  }
}

resource "aws_lb_listener" "video_streaming_site" {
  load_balancer_arn = aws_elb.video_streaming_site.id

  default_action {
    target_group_arn = aws_lb_target_group.video_streaming_site.id
    type             = "forward"
  }
}

resource "aws_iam_role" "video_streaming_site_lambda" {
  name = var.video_streaming_site_lambda_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "video_streaming_site_lambda" {
  name = var.video_streaming_site_lambda_role_name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.video_content.arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "video_streaming_site_lambda" {
  function_name = var.video_streaming_site_lambda_name
  role          = aws_iam_role.video_streaming_site_lambda.arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.video_streaming_site_lambda_zip.output_base64sha256

  runtime = "nodejs12.x"

  environment {
    variables = {
      video_content_bucket_name = var.video_content_bucket_name
    }
  }
}

resource "aws_cloudwatch_log_group" "video_streaming_site_lambda" {
  name = var.video_streaming_site_lambda_log_group_name

  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "video_streaming_site_lambda" {
  log_group_name = aws_cloudwatch_log_group.video_streaming_site_lambda.name
  name           = var.video_streaming_site_lambda_log_stream_name
}