provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ec2_role" {
  name = "eb_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_db_instance" "myapp_db" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  identifier           = "myapp-db"
  name                 = "mydatabase"
  username             = "admin"
  password             = "password123"
  skip_final_snapshot  = true
}

resource "aws_elb" "blue_elb" {
  name               = "blue-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

resource "aws_elb" "green_elb" {
  name               = "green-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

resource "aws_route53_health_check" "blue_hc" {
  fqdn              = aws_elb.blue_elb.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  measure_latency   = true
}

resource "aws_route53_health_check" "green_hc" {
  fqdn              = aws_elb.green_elb.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  measure_latency   = true
}

resource "aws_route53_record" "blue" {
  zone_id = "Z1234567890ABCDEFGHIJKL" # Replace with your hosted zone ID
  name    = "blue.example.com"
  type    = "A"

  alias {
    name                   = aws_elb.blue_elb.dns_name
    zone_id                = aws_elb.blue_elb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = "Z1234567890ABCDEFGHIJKL" # Replace with your hosted zone ID
  name    = "green.example.com"
  type    = "A"

  alias {
    name                   = aws_elb.green_elb.dns_name
    zone_id                = aws_elb.green_elb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "failover" {
  zone_id = "Z1234567890ABCDEFGHIJKL" # Replace with your hosted zone ID
  name    = "example.com"
  type    = "A"

  set_identifier = "blue"
  alias {
    name                   = aws_route53_record.blue.alias[0].name
    zone_id                = aws_route53_record.blue.alias[0].zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.blue_hc.id
}

resource "aws_route53_record" "failover_green" {
  zone_id = "Z1234567890ABCDEFGHIJKL" # Replace with your hosted zone ID
  name    = "example.com"
  type    = "A"

  set_identifier = "green"
  alias {
    name                   = aws_route53_record.green.alias[0].name
    zone_id                = aws_route53_record.green.alias[0].zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "SECONDARY"
  }
  health_check_id = aws_route53_health_check.green_hc.id
}