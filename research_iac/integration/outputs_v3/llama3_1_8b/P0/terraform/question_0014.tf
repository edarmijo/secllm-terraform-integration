provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "instance_profile" {
  name        = "eb_ec2_profile"
  description = "Instance profile for Elastic Beanstalk environment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "instance_profile_attach" {
  role       = aws_iam_role.instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_elastic_beanstalk_environment" "example" {
  name                = "my-env"
  application         = "my-app"
  description         = "My Elastic Beanstalk environment"
  tier                 = "webserver"
  platform             = "64bit Amazon Linux 2 v3.0.5 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCID"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.default.*.id
  }
}

resource "aws_db_instance" "default" {
  identifier           = "mydb"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.default.id]
}

resource "aws_db_instance" "default_link" {
  identifier           = aws_elastic_beanstalk_environment.example.name
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.default.id]
}

resource "aws_elastic_beanstalk_environment" "example_linked" {
  name                = aws_db_instance.default_link.identifier
  application         = "my-app"
  description         = "My Elastic Beanstalk environment linked to a relational database instance"
  tier                 = "webserver"
  platform             = "64bit Amazon Linux 2 v3.0.5 running Docker"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCID"
    value     = aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.default.*.id
  }
}