provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_environment" "example" {
  name            = "my-eb-env"
  application     = "my-app"
  solution_stack   = "64bit Amazon Linux 2018.03 v2.7.0 running Docker 18.06.1-ce"

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "2"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "4"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME"
    value     = "mydb"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USER"
    value     = "myuser"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = "mypassword"
  }
}