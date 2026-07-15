provider "aws" {
  region = "us-west-2"
}

resource "aws_elb" "main" {
  name               = "main-elb"
  availability_zones = ["us-west-2a", "us-west-2b"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_route53_zone" "primary" {
  name = "example.com"
}

resource "aws_route53_record" "elb_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "main.example.com"
  type    = "A"
  ttl     = 300
  records = [aws_elb.main.dns_name]
}