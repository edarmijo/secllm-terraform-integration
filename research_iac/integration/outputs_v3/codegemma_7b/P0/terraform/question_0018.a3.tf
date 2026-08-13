provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "web_app_role" {
  name = "web_app_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "web_app_role_policy" {
  role       = aws_iam_role.web_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkFullAccess"
}

resource "aws_vpc" "web_app_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "web_app_igw" {
  vpc_id = aws_vpc.web_app_vpc.id
}

resource "aws_subnet" "web_app_subnet_a" {
  vpc_id        = aws_vpc.web_app_vpc.id
  cidr_block    = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "web_app_subnet_b" {
  vpc_id        = aws_vpc.web_app_vpc.id
  cidr_block    = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_route_table" "web_app_route_table" {
  vpc_id = aws_vpc.web_app_vpc.id
}

resource "aws_route_table_association" "web_app_route_table_association_a" {
  route_table_id = aws_route_table.web_app_route_table.id
  subnet_id      = aws_subnet.web_app_subnet_a.id
}

resource "aws_route_table_association" "web_app_route_table_association_b" {
  route_table_id = aws_route_table.web_app_route_table.id
  subnet_id      = aws_subnet.web_app_subnet_b.id
}

resource "aws_rds_db_instance" "web_app_db" {
  engine         = "mysql"
  engine_version = "8.0.27"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  username = "admin"
  password = "password"
  db_name = "web_app_db"
  vpc_security_group_ids = [aws_security_group.web_app_sg.id]
}

resource "aws_security_group" "web_app_sg" {
  name = "web_app_sg"
  vpc_id = aws_vpc.web_app_vpc.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_elastic_beanstalk_application" "web_app_app" {
  name = "web_app_app"
}

resource "aws_elastic_beanstalk_environment" "web_app_env" {
  name = "web_app_env"
  application = aws_elastic_beanstalk_application.web_app_app.name
  version_label = "latest"
  solution_stack_name = "64bit Amazon Linux 2 v3.3"

  option_settings {
    namespace = "aws:elasticbeanstalk:environment"
    option_name = "EnvironmentType"
    value = "LoadBalanced"
  }

  option_settings {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    option_name = "SystemType"
    value = "EC2"
  }

  option_settings {
    namespace = "aws:elasticbeanstalk:application:environment"
    option_name = "DatabaseConnectionSettingName"
    value = aws_rds_db_instance.web_app_db.db_instance_identifier
  }
}