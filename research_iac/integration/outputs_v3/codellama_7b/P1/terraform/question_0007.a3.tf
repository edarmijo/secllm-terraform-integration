resource "aws_elastic_beanstalk_environment" "my_api_env" {
  name                = "my-api-env"
  application         = aws_elastic_beanstalk_application.my_api_app.name
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.5 running Node.js 10"
  instance_profile    = aws_iam_instance_profile.eb_ec2_profile.id

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperBreachScaleIncrement"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerBreachScaleIncrement"
    value     = "1"
  }
}