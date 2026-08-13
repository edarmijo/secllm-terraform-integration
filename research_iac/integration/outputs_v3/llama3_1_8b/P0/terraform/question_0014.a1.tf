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

resource "aws_elastic_beanstalk_environment" "example_linked" {
  name                = "my-env"
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
  identifier           = aws_elastic_beanstalk_environment.example_linked.name
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  username             = "admin"
  password             = "password"
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.default.id]
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "default" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.default.id
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "default" {
  name        = "my-sg"
  description = "My security group"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}