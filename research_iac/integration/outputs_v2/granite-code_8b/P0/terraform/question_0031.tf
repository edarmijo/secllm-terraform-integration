resource "aws_elastic_beanstalk_application" "example" {
  name = "example-app"

  setting {
    namespace = "aws:autoscaling:asg"
    option_name  = "MinSize"
    value       = "2"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    option_name  = "MaxSize"
    value       = "4"
  }
}