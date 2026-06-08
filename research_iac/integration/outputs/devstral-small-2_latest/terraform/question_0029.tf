provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "go_app" {
  name        = "go-application"
  description = "Go application running on Elastic Beanstalk"
}

resource "aws_elastic_beanstalk_environment" "go_env" {
  name                = "go-environment"
  application         = aws_elastic_beanstalk_application.go_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Go 1"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", aws_subnet.public.*.id)
  }
}

resource "aws_iam_role" "eb_role" {
  name = "elastic-beanstalk-ec2-role"

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

resource "aws_iam_role_policy_attachment" "eb_ec2_policy" {
  role       = aws_iam_role.eb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "elastic-beanstalk-ec2-instance-profile"
  role = aws_iam_role.eb_role.name
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

data "aws_availability_zones" "available" {
  state = "available"
}