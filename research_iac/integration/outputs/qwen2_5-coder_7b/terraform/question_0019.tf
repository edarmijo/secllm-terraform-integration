provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "eb_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "eb_vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eb_vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.eb_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "eb_subnet_public_1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.eb_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

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
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "eb_env_sg" {
  vpc_id = aws_vpc.eb_vpc.id

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

resource "aws_db_subnet_group" "shared_rds_subnet_group" {
  name       = "shared_rds_subnet_group"
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "shared_rds_subnet_group"
  }
}

resource "aws_db_instance" "shared_rds" {
  identifier            = "shared_rds"
  instance_class        = "db.t3.micro"
  engine                = "mysql"
  engine_version        = "5.7"
  username              = "admin"
  password              = "password123"
  allocated_storage     = 20
  db_subnet_group_name  = aws_db_subnet_group.shared_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.eb_env_sg.id]

  tags = {
    Name = "shared_rds"
  }
}

resource "aws_elastic_beanstalk_environment" "env1" {
  name                = "env1"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v3.5.0 running Python 3.8"

  environment_properties = [
    { Name = "DB_HOSTNAME", Value = aws_db_instance.shared_rds.address },
    { Name = "DB_USERNAME", Value = aws_db_instance.shared_rds.username },
    { Name = "DB_PASSWORD", Value = aws_db_instance.shared_rds.password }
  ]

  tags = {
    Name = "env1"
  }
}

resource "aws_elastic_beanstalk_environment" "env2" {
  name                = "env2"
  application         = "my-app"
  solution_stack_name = "64bit Amazon Linux 2 v3.5.0 running Python 3.8"

  environment_properties = [
    { Name = "DB_HOSTNAME", Value = aws_db_instance.shared_rds.address },
    { Name = "DB_USERNAME", Value = aws_db_instance.shared_rds.username },
    { Name = "DB_PASSWORD", Value = aws_db_instance.shared_rds.password }
  ]

  tags = {
    Name = "env2"
  }
}