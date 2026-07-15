provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "eb_ec2_role"

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

resource "aws_iam_role_policy" "eb_ec2_policy" {
  name   = "eb_ec2_policy"
  role   = aws_iam_role.eb_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups",
          "cloudwatch:GetMetricStatistics"
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "eb_ec2_profile"

  roles = [
    aws_iam_role.eb_ec2_role.name
  ]
}

resource "aws_elastic_beanstalk_application" "my_api_app" {
  application_name = "my_api_app"
}

resource "aws_autoscaling_group" "my_asg" {
  name                 = "my_asg"
  launch_template      = aws_launch_template.my_lt.id
  min_size             = 1
  max_size             = 5
  desired_capacity     = 3
  vpc_zone_identifier  = ["subnet-0a1b2c3d4e5f67890", "subnet-0a1b2c3d4e5f67891"]
  load_balancer_names  = [aws_elastic_load_balancer.my_lb.name]
  health_check_type    = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "my_asg"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "my_lt" {
  name_prefix = "my_lt_"

  instance_type = "t2.micro"
  image_id      = "ami-0c55b159cbfafe1f0"
  key_name      = "my-key-pair"
  iam_instance_profile = aws_iam_instance_profile.eb_ec2_profile.arn

  user_data = base64encode(<<EOF
#!/bin/bash
# Your application setup script here
EOF
)

  tag {
    key                 = "Name"
    value               = "my_lt"
    propagate_at_launch = true
  }
}

resource "aws_elastic_load_balancer" "my_lb" {
  name               = "my_lb"
  internal           = false
  security_groups    = [aws_security_group.my_sg.id]
  subnets            = ["subnet-0a1b2c3d4e5f67890", "subnet-0a1b2c3d4e5f67891"]

  tag {
    key                 = "Name"
    value               = "my_lb"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "my_sg" {
  name        = "my_sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elastic_beanstalk_environment" "my_env" {
  application       = aws_elastic_beanstalk_application.my_api_app.application_name
  environment_name  = "my-env"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Python 3.8"

  option_settings = [
    {
      namespace        = "aws:autoscaling:asg"
      option_name      = "MinSize"
      value            = "1"
    },
    {
      namespace        = "aws:autoscaling:asg"
      option_name      = "MaxSize"
      value            = "5"
    },
    {
      namespace        = "aws:autoscaling:asg"
      option_name      = "DesiredCapacity"
      value            = "3"
    },
    {
      namespace        = "aws:ec2:instances"
      option_name      = "InstanceTypes"
      value            = "t2.micro"
    },
    {
      namespace        = "aws:autoscaling:launchconfiguration"
      option_name      = "IamInstanceProfile"
      value            = aws_iam_instance_profile.eb_ec2_profile.arn
    },
    {
      namespace        = "aws:elb:healthcheck"
      option_name      = "Target"
      value            = "HTTP:80/"
    },
    {
      namespace        = "aws:autoscaling:trigger"
      option_name      = "AutoScalingGroupName"
      value            = aws_autoscaling_group.my_asg.name
    },
    {
      namespace        = "aws:autoscaling:trigger"
      option_name      = "MetricName"
      value            = "CPUUtilization"
    },
    {
      namespace        = "aws:autoscaling:trigger"
      option_name      = "ComparisonOperator"
      value            = "GreaterThanThreshold"
    },
    {
      namespace        = "aws:autoscaling:trigger"
      option_name      = "EvaluationPeriods"
      value            = "1"
    },
    {
      namespace        = "aws:autoscaling:trigger"
      option_name      = "Period"
      value            = "300"
    },
    {
      namespace        = "aws:autoscaling:trigger"
      option_name      = "Threshold"
      value            = "50"
    },
    {
      namespace        = "aws:autoscaling:trigger"
      option_name      = "Statistic"
      value            = "Average"
    },
    {
      namespace        = "aws:autoscaling:trigger"
      option_name      = "TreatMissingData"
      value            = "breaching"
    }
  ]
}