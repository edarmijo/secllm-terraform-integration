# Configure Route 53 resources
resource "aws_route53_zone" "example" {
  name = "example.com"
}

resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.example.id
  name    = "www"
  type    = "A"

  alias_target {
    hosted_zone_id = "Z26RNL4JYFTOTI" # Replace with the ID of your hosted zone
    dns_name       = "myenv-EB-1234567890.us-east-1.elb.amazonaws.com" # Replace with the DNS name of your Elastic Beanstalk environment
  }
}

# Configure Elastic Beanstalk resources
resource "aws_elasticbeanstalk_application" "myenv" {
  name = "myenv"
}

resource "aws_elasticbeanstalk_environment" "myenv" {
  application = aws_elasticbeanstalk_application.myenv.name
  instance_profiles = [
    "eb_ec2_profile1",
  ]

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
}

# Configure RDS resources
resource "aws_db_instance" "myapp_db" {
  identifier           = "myapp_db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  username             = "myuser"
  password             = "mypassword"
  skip_final_snapshot = true

  db_subnet_group_name = "my subnet group"
}