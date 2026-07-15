provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "ec2_profile" {
  name = "eb_ec2_profile"

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

resource "aws_iam_instance_profile" "ec2_profile" {
  name = aws_iam_role.ec2_profile.name
  roles = [aws_iam_role.ec2_profile.name]
}

resource "aws_rds_db_instance" "myapp_db" {
  identifier             = "myapp_db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "password123"
  allocated_storage      = 20
  storage_type           = "gp2"
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.myapp_sg.id]
}

resource "aws_security_group" "myapp_sg" {
  name        = "myapp_sg"
  description = "Security group for my app"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_zone" "myapp_zone" {
  name = "example.com"
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.myapp_zone.zone_id
  name    = "blue.example.com"
  type    = "A"
  ttl     = 300

  alias {
    name                   = aws_elb.blue.name
    zone_id                = aws_elb.blue.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.myapp_zone.zone_id
  name    = "green.example.com"
  type    = "A"
  ttl     = 300

  alias {
    name                   = aws_elb.green.name
    zone_id                = aws_elb.green.zone_id
    evaluate_target_health = true
  }
}

resource "aws_elb" "blue" {
  availability_zones = ["us-west-2a"]
  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_elb" "green" {
  availability_zones = ["us-west-2a"]
  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_route53_record" "blue_failover" {
  zone_id = aws_route53_zone.myapp_zone.zone_id
  name    = "blue.example.com"
  type    = "A"
  ttl     = 300

  failover_routing_policy {
    primary {
      record_set {
        name    = aws_elb.blue.name
        type    = "A"
        ttl     = 300
        alias {
          name                   = aws_elb.green.name
          zone_id                = aws_elb.green.zone_id
          evaluate_target_health = true
        }
      }
    }
  }
}

resource "aws_route53_record" "green_failover" {
  zone_id = aws_route53_zone.myapp_zone.zone_id
  name    = "green.example.com"
  type    = "A"
  ttl     = 300

  failover_routing_policy {
    primary {
      record_set {
        name    = aws_elb.green.name
        type    = "A"
        ttl     = 300
        alias {
          name                   = aws_elb.blue.name
          zone_id                = aws_elb.blue.zone_id
          evaluate_target_health = true
        }
      }
    }
  }
}