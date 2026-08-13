provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "vpc_cidr_block" {
  secret_id = "vpc-cidr-block"
}

data "aws_secretsmanager_secret_version" "vpc_name" {
  secret_id = "vpc-name"
}

resource "aws_vpc" "example" {
  cidr_block = data.aws_secretsmanager_secret_version.vpc_cidr_block.secret_string
  tags       = {
    Name = data.aws_secretsmanager_secret_version.vpc_name.secret_string
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}