resource "aws_elastic_beanstalk_environment" "example" {
  name            = "my-api-env"
  application     = aws_elastic_beanstalk_application.my_api_app.name
  solution_stack   = "64bit Amazon Linux 2018.03 v2.14.28 running Docker 18.09.9ce-1.el7"

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
    namespace = "aws:autoscaling:asg"
    name      = " desiredCapacity"
    value     = "3"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "EC2 CPU Credit Balance"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "BreachDuration"
    value     = "60"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MetricName"
    value     = "CPUCreditBalance"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = " statistic"
    value     = "Average"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "10"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "50"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "EvaluationPeriods"
    value     = "2"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "60"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "ComparisonOperator"
    value     = "GreaterThanThreshold"
  }
}