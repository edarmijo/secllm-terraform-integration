provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "example" {
  name = "example.com."
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = "example.com."
  type    = "NS"

  records = [
    "ns-1087.awsdns-11.org.",
    "ns-1986.awsdns-57.co.uk.",
    "ns-1419.awsdns-35.com.",
    "ns-1902.awsdns-47.net.",
  ]

  ttl = "172800"
}

resource "aws_route53_record" "beanstalk" {
  zone_id = aws_route53_zone.example.id
  name    = "myenv.example.com."
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.myenv.cname
    zone_id                = aws_elastic_beanstalk_environment.myenv.zone_name
    evaluate_target_health = false
  }
}

resource "aws_elastic_beanstalk_environment" "myenv" {
  name                = "myenv"
  application         = "example-app"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.4 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", aws_subnet.default.*.id)
  }
}

resource "aws_elastic_beanstalk_environment" "myenv_db" {
  name                = "myenv-db"
  application         = "example-app"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.4 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", aws_subnet.default.*.id)
  }
}

resource "aws_iam_role" "eb_ec2_profile1" {
  name        = "eb_ec2_profile1"
  description = "Elastic Beanstalk EC2 role"

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

resource "aws_iam_role_policy" "eb_ec2_profile1" {
  name   = "eb_ec2_profile1-policy"
  role   = aws_iam_role.eb_ec2_profile1.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.example.arn
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshots",
        ]
        Effect   = "Allow"
        Resource = aws_rds_cluster.myapp_db.arn
      },
    ]
  })
}

resource "aws_rds_cluster" "myapp_db" {
  cluster_identifier         = "myapp-db-cluster"
  database_name              = "myapp_db"
  master_username            = "admin"
  master_user_password       = "password123"
  vpc_security_group_ids     = [aws_security_group.default.id]
  skip_final_snapshot        = true
  db_subnet_group_name      = aws_db_subnet_group.default.name

  iam_database_authentication_enabled = true
}

resource "aws_elastic_beanstalk_environment" "myenv_db_env" {
  name                = "myenv-db-env"
  application         = "example-app"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.4 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", aws_subnet.default.*.id)
  }
}