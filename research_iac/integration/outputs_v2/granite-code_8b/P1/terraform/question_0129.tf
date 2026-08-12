# Define variables for security best practices
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "us-east-1"
}

# Create an IAM role for the EC2 instances
resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Create an IAM role for the RDS instance
resource "aws_iam_role" "rds_role" {
  name               = "rds-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Create a VPC with three subnets
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "My VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Private Subnet 2"
  }
}

# Create an EC2 instance in the public subnet running web servers
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with the latest Amazon Linux AMI ID
  instance_type = "t2.micro"

  security_groups = [
    aws_security_group.web_server_sg.id,
  ]

  tags = {
    Name = "WebServer"
  }
}

# Create an EC2 instance in the private subnet running the application servers
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0" # Replace with the latest Amazon Linux AMI ID
  instance_type = "t2.micro"

  security_groups = [
    aws_security_group.app_server_sg.id,
  ]

  tags = {
    Name = "AppServer"
  }
}

# Create an RDS instance in the private subnet serving as the database
resource "aws_db_instance" "my_rds_instance" {
  engine           = "mysql"
  engine_version    = "5.7"
  instance_class   = "db.t2.micro"
  name             = "my-rds-instance"
  username         = "admin"
  password         = "MySuperSecretPassword"
  storage_encrypted = true

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
  ]

  tags = {
    Name = "RDSInstance"
  }
}