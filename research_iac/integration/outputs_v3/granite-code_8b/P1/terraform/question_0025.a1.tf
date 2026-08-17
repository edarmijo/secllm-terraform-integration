# Configure multi-region application deployment with Route 53 resources

# Create a Route 53 hosted zone for the domain
resource "aws_route53_zone" "mydomain" {
  name = "mydomain.com"
}

# Create a Route 53 record for the us-east-1 alias
resource "aws_route53_record" "us_east_1_alias" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = "us-east-1"
  type    = "A"
  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI"
    dns_name       = "us-east-1-elasticbeanstalk-env.elb.us-east-1.amazonaws.com"
    evaluate_target_health = false
  }
}

# Create a Route 53 record for the eu-west-1 alias
resource "aws_route53_record" "eu_west_1_alias" {
  zone_id = aws_route53_zone.mydomain.zone_id
  name    = "eu-west-1"
  type    = "A"
  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI"
    dns_name       = "eu-west-1-elasticbeanstalk-env.elb.eu-west-1.amazonaws.com"
    evaluate_target_health = false
  }
}

# Create an Elastic Beanstalk environment for the us-east-1 region
resource "aws_elastic_beanstalk_environment" "myenv_us_east" {
  name = "myenv_us_east"
  application = "myapp_us_east"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.14.13 running Docker 18.09.9ce-1.el7"
  setting {
    name  = "AWSEBHealthReporting"
    value = "true"
  }
  setting {
    name  = "AWSEBContainerCommand"
    value = "Nice"
  }
}

# Create an Elastic Beanstalk environment for the eu-west-1 region
resource "aws_elastic_beanstalk_environment" "myenv_eu_west" {
  name = "myenv_eu_west"
  application = "myapp_eu_west"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.14.13 running Docker 18.09.9ce-1.el7"
  setting {
    name  = "AWSEBHealthReporting"
    value = "true"
  }
  setting {
    name  = "AWSEBContainerCommand"
    value = "Nice"
  }
}

# Create an RDS database for the us-east-1 region
resource "aws_db_instance" "main_db_us_east" {
  identifier = "main_db_us_east"
  engine = "mysql"
  engine_version = "5.7.21"
  instance_class = "db.t2.micro"
  username = "myuser"
  password = "mypassword"
  skip_final_snapshot = true
}

# Create an RDS database for the eu-west-1 region
resource "aws_db_instance" "main_db_eu_west" {
  identifier = "main_db_eu_west"
  engine = "mysql"
  engine_version = "5.7.21"
  instance_class = "db.t2.micro"
  username = "myuser"
  password = "mypassword"
  skip_final_snapshot = true
}