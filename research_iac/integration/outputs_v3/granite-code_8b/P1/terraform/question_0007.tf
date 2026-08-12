resource "aws_elastic_beanstalk_application" "my_api_app" {
  name = "my-api-app"
}

resource "aws_elastic_beanstalk_environment" "my_api_env" {
  application = aws_elastic_beanstalk_application.my_api_app.name

  autoscaling_rules {
    metric_name     = "CPUUtilisation"
    lower_threshold = 10
    upper_threshold = 50
    period          = 60
    evaluation_periods = 2
  }
}