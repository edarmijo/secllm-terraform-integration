resource "aws_elastic_beanstalk_environment" "example" {
  name            = "my-eb-env"
  application     = aws_elastic_beanstalk_application.example.name
  solution_stack   = "64bit Amazon Linux 2018.03 v2.14.5 running Docker 18.09.1ce-1.el7"

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_INSTANCE"
    value     = aws_db_instance.default.address
  }
}