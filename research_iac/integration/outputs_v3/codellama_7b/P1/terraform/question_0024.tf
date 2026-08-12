provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example.com."
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = "www"
  type    = "A"
  ttl     = 60
  records = [aws_elastic_beanstalk_environment.myenv.load_balancer.dns_name]
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  name                = "myenv"
  instance_profile    = aws_iam_instance_profile.eb_ec2_profile1.arn
  load_balancer       = true
  load_balancer_type  = "application"
  load_balancer_scheme = "internet-facing"
}

resource "aws_rds_cluster" "myapp_db" {
  cluster_identifier   = "myapp-db"
  engine               = "aurora-postgresql"
  engine_version       = "10.7"
  instance_type        = "db.t2.small"
  database_name        = "myapp"
  master_username      = "admin"
  master_password      = var.rds_master_password
  backup_retention_days = 10
}

resource "aws_iam_instance_profile" "eb_ec2_profile1" {
  name = "eb_ec2_profile1"
  role = aws_iam_role.eb_ec2_role1.name
}

resource "aws_iam_role" "eb_ec2_role1" {
  name               = "eb_ec2_role1"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}