provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret" "vpc_cidr_block" {
  name = "vpc-cidr-block"
}

data "aws_secretsmanager_secret" "vpc_name" {
  name = "vpc-name"
}

resource "aws_vpc" "example" {
  cidr_block = data.aws_secretsmanager_secret.vpc_cidr_block.value
  tags       = {
    Name = data.aws_secretsmanager_secret.vpc_name.name
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}