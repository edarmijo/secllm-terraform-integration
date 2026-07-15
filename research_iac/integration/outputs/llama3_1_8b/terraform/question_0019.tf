provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "eb_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "eb_vpc" }
}

resource "aws_internet_gateway" "eb_igw" {
  vpc_id = aws_vpc.eb_vpc.id
  tags   = { Name = "eb_igw" }
}

resource "aws_subnet" "eb_subnet_public_1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.eb_vpc.id
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  tags       = { Name = "eb_subnet_public_1" }
}

resource "aws_subnet" "eb_subnet_public_2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.eb_vpc.id
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  tags       = { Name = "eb_subnet_public_2" }
}

resource "aws_security_group" "eb_env_sg" {
  name        = "eb_env_sg"
  description = "Security group for Elastic Beanstalk environment"
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
}

resource "aws_route_table" "eb_rt" {
  vpc_id = aws_vpc.eb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eb_igw.id
  }

  tags       = { Name = "eb_rt" }
}

resource "aws_route_table_association" "eb_rta_1" {
  subnet_id      = aws_subnet.eb_subnet_public_1.id
  route_table_id = aws_route_table.eb_rt.id
}

resource "aws_route_table_association" "eb_rta_2" {
  subnet_id      = aws_subnet.eb_subnet_public_2.id
  route_table_id = aws_route_table.eb_rt.id
}

resource "aws_db_instance" "shared_rds" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "shared_rds"
  username             = "admin"
  password             = "password"
  vpc_security_group_ids = [aws_security_group.eb_env_sg.id]
  db_subnet_group_name = aws_db_subnet_group.shared_rds.name
}

resource "aws_db_subnet_group" "shared_rds" {
  name       = "shared_rds"
  subnet_ids = [aws_subnet.eb_subnet_public_1.id, aws_subnet.eb_subnet_public_2.id]

  tags = {
    Name = "shared_rds"
  }
}

resource "aws_elastic_beanstalk_environment" "env_1" {
  name                = "env-1"
  application         = "my-app"
  tier                = "webserver-medium"
  environment_name   = "dev-env"

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
}

resource "aws_elastic_beanstalk_environment" "env_2" {
  name                = "env-2"
  application         = "my-app"
  tier                = "webserver-medium"
  environment_name   = "prod-env"

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
}