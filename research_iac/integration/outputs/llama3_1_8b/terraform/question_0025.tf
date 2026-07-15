provider "aws" {
  region = "us-east-1"
}

# Create IAM roles for Elastic Beanstalk environments
resource "aws_iam_role" "eb_ec2_profile3" {
  name        = "eb_ec2_profile3"
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
      }
    ]
  })
}

# Create IAM roles for Elastic Beanstalk environments
resource "aws_iam_role_policy" "eb_ec2_profile3_policy" {
  name   = "eb_ec2_profile3_policy"
  role   = aws_iam_role.eb_ec2_profile3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBParameters",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Create Elastic Beanstalk environments
resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  name                = "myenv_us_east"
  application         = aws_elastic_beanstalk_application.myapp_us_east.name
  environment_name    = "dev-us-east-1"
  tier               = "webserver-medium"
  platform           = "64bit Amazon Linux 2 v3.0.10 running Docker"
}

resource "aws_elastic_beanstalk_environment" "myenv_eu_west" {
  name                = "myenv_eu_west"
  application         = aws_elastic_beanstalk_application.myapp_eu_west.name
  environment_name    = "dev-eu-west-1"
  tier               = "webserver-medium"
  platform           = "64bit Amazon Linux 2 v3.0.10 running Docker"
}

# Create Elastic Beanstalk applications
resource "aws_elastic_beanstalk_application" "myapp_us_east" {
  name        = "myapp_us_east"
  description = "My application in us-east-1"
}

resource "aws_elastic_beanstalk_application" "myapp_eu_west" {
  name        = "myapp_eu_west"
  description = "My application in eu-west-1"
}

# Create RDS databases
resource "aws_db_instance" "main_db_us_east" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb-us-east-1"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.sg_us_east.id]
}

resource "aws_db_instance" "main_db_eu_west" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb-eu-west-1"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.sg_eu_west.id]
}

# Create Route 53 resources
resource "aws_route53_zone" "mydomain" {
  name        = "example.com."
}

resource "aws_route53_record" "us-east-1_alias" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = "us-east-1.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.myenv_us_east.endpoint_url
    zone_id                = aws_elastic_beanstalk_environment.myenv_us_east.zone_name
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "eu-west-1_alias" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = "eu-west-1.example.com"
  type    = "A"

  alias {
    name                   = aws_elastic_beanstalk_environment.myenv_eu_west.endpoint_url
    zone_id                = aws_elastic_beanstalk_environment.myenv_eu_west.zone_name
    evaluate_target_health = false
  }
}

# Create security groups for RDS databases
resource "aws_security_group" "sg_us_east" {
  name        = "sg-us-east-1"
  description = "Security group for us-east-1 RDS database"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_eu_west" {
  name        = "sg-eu-west-1"
  description = "Security group for eu-west-1 RDS database"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}