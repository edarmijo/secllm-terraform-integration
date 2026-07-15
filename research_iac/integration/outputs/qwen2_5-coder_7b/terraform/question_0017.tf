provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "eb_ec2_profile" {
  name = "eb_ec2_profile"

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
  role   = aws_iam_role.eb_ec2_profile.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:StartInstances",
          "ec2:TerminateInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_db_instance" "my_db1" {
  identifier             = "my_db1"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "password"
  allocated_storage      = 20
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Security group for RDS"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elastic_beanstalk_environment" "my_env" {
  name                = "my-env"
  application         = aws_elastic_beanstalk_application.my_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running Python 3.8"

  environment_properties = [
    { Name = "AWS::EC2::InstanceProfile", Value = aws_iam_role.eb_ec2_profile.arn },
    { Name = "DB_HOSTNAME", Value = aws_db_instance.my_db1.address },
    { Name = "DB_USERNAME", Value = aws_db_instance.my_db1.username },
    { Name = "DB_PASSWORD", Value = aws_db_instance.my_db1.password },
  ]

  autoscaling_group_name = aws_autoscaling_group.my_asg.name
}

resource "aws_autoscaling_group" "my_asg" {
  name                 = "my-asg"
  launch_template      = aws_launch_template.my_lt.id
  min_size             = 1
  max_size             = 5
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public_subnets[0].id]
  target_group_arns    = [aws_lb_target_group.my_tg.arn]

  health_check_type    = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "my-asg"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "my_lt" {
  name_prefix = "my-lt-"

  instance_type = "t2.micro"

  iam_instance_profile {
    arn = aws_iam_role.eb_ec2_profile.arn
  }

  user_data = base64encode(file("user-data.sh"))
}

resource "aws_lb_target_group" "my_tg" {
  name     = "my-tg"
  port     = 80
  protocol = "HTTP"

  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "my_lb" {
  name               = "my-lb"
  internal           = false
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

  target_group_arns = [aws_lb_target_group.my_tg.arn]

  listener {
    protocol     = "HTTP"
    port         = 80
    default_action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.my_tg.arn
    }
  }
}

resource "aws_security_group" "elb_sg" {
  name        = "elb_sg"
  description = "Security group for ELB"

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_elastic_beanstalk_application" "my_app" {
  name        = "my-app"
  description = "My Elastic Beanstalk Application"
}