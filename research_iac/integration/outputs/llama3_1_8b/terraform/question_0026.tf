provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "blue" {
  ami           = "ami-abcd1234"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.blue.id]
}

resource "aws_instance" "green" {
  ami           = "ami-abcd1234"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.green.id]
}

resource "aws_security_group" "blue" {
  name        = "blue-sg"
  description = "Security group for blue environment"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "green" {
  name        = "green-sg"
  description = "Security group for green environment"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_instance" "myapp_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  name                   = "myapp-db"
  username               = "admin"
  password               = "password"
  vpc_security_group_ids = [aws_security_group.myapp.id]
}

resource "aws_security_group" "myapp" {
  name        = "myapp-sg"
  description = "Security group for RDS instance"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "eb_ec2_profile" {
  name        = "eb-ec2-profile"
  description = "Instance profile for Elastic Beanstalk EC2 instances"

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

resource "aws_iam_role_policy" "eb_ec2_profile_policy" {
  name   = "eb-ec2-profile-policy"
  role   = aws_iam_role.eb_ec2_profile.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBParameterGroups",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_route53_zone" "myapp" {
  name            = "myapp.com"
  comment         = "Managed by Terraform"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.myapp.zone_id
  name    = "blue.myapp.com"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname_name
    zone_id                = aws_elastic_beanstalk_environment.blue.cname_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.myapp.zone_id
  name    = "green.myapp.com"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname_name
    zone_id                = aws_elastic_beanstalk_environment.green.cname_zone_id
    evaluate_target_health = true
  }
}

resource "aws_elastic_beanstalk_environment" "blue" {
  name        = "myapp-blue-env"
  application = "myapp"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.4 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name       = "VPCId"
    value      = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name       = "Subnets"
    value      = jsonencode([aws_subnet.default.id])
  }
}

resource "aws_elastic_beanstalk_environment" "green" {
  name        = "myapp-green-env"
  application = "myapp"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.4 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name       = "VPCId"
    value      = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name       = "Subnets"
    value      = jsonencode([aws_subnet.default.id])
  }
}

resource "aws_route53_health_check" "blue" {
  alarm_id               = "myapp-blue-health-check-alarm"
  enabled                = true
  hosted_zone_id         = aws_route53_zone.myapp.zone_id
  ip_address             = "52.34.12.123"
  port                  = 80
  type                   = "HTTP"
}

resource "aws_route53_health_check" "green" {
  alarm_id               = "myapp-green-health-check-alarm"
  enabled                = true
  hosted_zone_id         = aws_route53_zone.myapp.zone_id
  ip_address             = "52.34.12.123"
  port                  = 80
  type                   = "HTTP"
}

resource "aws_route53_record" "blue_failover" {
  zone_id = aws_route53_zone.myapp.zone_id
  name    = "myapp.com"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname_name
    zone_id                = aws_elastic_beanstalk_environment.blue.cname_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green_failover" {
  zone_id = aws_route53_zone.myapp.zone_id
  name    = "myapp.com"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname_name
    zone_id                = aws_elastic_beanstalk_environment.green.cname_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "blue_failover_routing_policy" {
  zone_id = aws_route53_zone.myapp.zone_id
  name    = "myapp.com"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.blue.cname_name
    zone_id                = aws_elastic_beanstalk_environment.blue.cname_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "green_failover_routing_policy" {
  zone_id = aws_route53_zone.myapp.zone_id
  name    = "myapp.com"
  type    = "A"
  alias {
    name                   = aws_elastic_beanstalk_environment.green.cname_name
    zone_id                = aws_elastic_beanstalk_environment.green.cname_zone_id
    evaluate_target_health = true
  }
}