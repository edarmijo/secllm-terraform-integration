provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret_version" "eb_access_key_id" {
  secret_id = var.eb_access_key_id_secret_id
}

data "aws_secretsmanager_secret_version" "eb_secret_access_key" {
  secret_id = var.eb_secret_access_key_secret_id
}

resource "aws_iam_role" "eb_ec2_role" {
  name               = "eb_ec2_role"
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

resource "aws_iam_role_policy" "eb_ec2_role_policy" {
  name   = "eb_ec2_role_policy"
  role   = aws_iam_role.eb_ec2_role.id
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
        Resource = "${aws_s3_bucket.eb_bucket.arn}/*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "my_api_env" {
  name                = "my-api-env"
  application         = var.elastic_beanstalk_app_name
  description         = "Elastic Beanstalk environment for my API app"
  tier                 = "webserver-medium"
  platform             = "Linux"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private_a.id},${aws_subnet.private_b.id}"
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy"
    name      = "Enabled"
    value     = true
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:RollingUpdate"
    name      = "MinInstancesInService"
    value     = 1
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:RollingUpdate"
    name      = "MaxInstancesInService"
    value     = 10
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:RollingUpdate"
    name      = "MinHealthyPercent"
    value     = 50
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:RollingUpdate"
    name      = "MaxHealthyPercent"
    value     = 100
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = false
  }
}

resource "aws_elastic_beanstalk_environment_config" "my_api_env_config" {
  environment_name = aws_elastic_beanstalk_environment.my_api_env.name

  tier                = "webserver-medium"
  platform            = "Linux"
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.default.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private_a.id},${aws_subnet.private_b.id}"
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy"
    name      = "Enabled"
    value     = true
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:RollingUpdate"
    name      = "MinInstancesInService"
    value     = 1
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:RollingUpdate"
    name      = "MaxInstancesInService"
    value     = 10
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:RollingUpdate"
    name      = "MinHealthyPercent"
    value     = 50
  }
  setting {
    namespace = "aws:autoscaling:updatePolicy:RollingUpdate"
    name      = "MaxHealthyPercent"
    value     = 100
  }
}

resource "aws_elastic_beanstalk_application" "my_api_app" {
  name        = var.elastic_beanstalk_app_name
  description = "Elastic Beanstalk application for my API app"
}