provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "video_content" {
  bucket = var.video_content_bucket_name
  acl    = "private"

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

resource "aws_route53_record" "video_streaming_site" {
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
    aws_subnet.video_streaming_site_public_subnet_1.id,
    aws_subnet.video_streaming_site_public_subnet_2.id,
  ]

  security_groups = [
    aws_security_group.video_streaming_site_elb_sg.id,
  ]

  listener {
    protocol           = "HTTPS"
    port               = 443
    certificate        = var.video_streaming_site_certificate_arn

    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.video_streaming_site_tg.id
    }
  }
}

resource "aws_lb_target_group" "video_streaming_site_tg" {
  name        = var.video_streaming_site_tg_name
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    path = "/healthz"
  }
}

resource "aws_lb_listener_rule" "video_streaming_site_lr" {
  listener_arn = aws_elb.video_streaming_site.id

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.video_streaming_site_tg.id
  }

  condition {
    field  = "path-pattern"
    values = ["/"]
  }
}

resource "aws_lb_listener_rule" "video_streaming_site_lr_video_content" {
  listener_arn = aws_elb.video_streaming_site.id

  action {
    type             = "redirect"
    redirect         = true
    port             = "443"
    protocol         = "HTTPS"
    host             = var.video_streaming_site_domain
    path             = "/video-content"
    query            = ""
    status_code      = "HTTP_301"
  }

  condition {
    field  = "path-pattern"
    values = ["/video-content/*"]
  }
}

resource "aws_lb_listener_rule" "video_streaming_site_lr_healthz" {
  listener_arn = aws_elb.video_streaming_site.id

  action {
    type             = "fixed-response"
    content_type     = "text/plain"
    message_body     = "OK"
    status_code      = "HTTP_200"
  }

  condition {
    field  = "path-pattern"
    values = ["/healthz"]
  }
}

resource "aws_lb_listener_rule" "video_streaming_site_lr_not_found" {
  listener_arn = aws_elb.video_streaming_site.id

  action {
    type             = "fixed-response"
    content_type     = "text/plain"
    message_body     = "Not Found"
    status_code      = "HTTP_404"
  }

  condition {
    field  = "path-pattern"
    values = ["*"]
  }
}