provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "eb_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eb_vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eb_vpc.id

  tags = {
    Name = "eb_igw"
  }
}

resource "aws_subnet" "eb_subnet_public_1" {
  vpc_id            = aws_vpc.eb_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "eb_subnet_public_1"
  }
}

resource "aws_subnet" "eb_subnet_public_2" {
  vpc_id            = aws_vpc.eb_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "eb_subnet_public_2"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.eb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "eb_public_rt"
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.eb_subnet_public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.eb_subnet_public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "eb_env_sg" {
  name        = "eb_env_sg"
  description = "Security group for Elastic Beanstalk environments"
  vpc_id      = aws_vpc.eb_vpc.id

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

  tags = {
    Name = "eb_env_sg"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "shared_rds_subnet_group"
  subnet_ids = [aws_subnet.eb_subnet_public_1.id, aws_subnet.eb_subnet_public_2.id]

  tags = {
    Name = "shared_rds_subnet_group"
  }
}

resource "aws_db_instance" "shared_rds" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_name                = "shareddb"
  username               = "admin"
  password               = "password123" # In production, use a proper secret management solution
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.eb_env_sg.id]

  tags = {
    Name = "shared_rds"
  }
}

resource "aws_elastic_beanstalk_environment" "env1" {
  name                = "eb-env-1"
  application         = "my-app-1"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.eb_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.eb_subnet_public_1.id},${aws_subnet.eb_subnet_public_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.eb_subnet_public_1.id},${aws_subnet.eb_subnet_public_2.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }
}

resource "aws_elastic_beanstalk_environment" "env2" {
  name                = "eb-env-2"
  application         = "my-app-2"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.7 running Node.js 14"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.eb_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.eb_subnet_public_1.id},${aws_subnet.eb_subnet_public_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.eb_subnet_public_1.id},${aws_subnet.eb_subnet_public_2.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }
}