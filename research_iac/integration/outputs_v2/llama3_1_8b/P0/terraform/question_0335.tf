provider "aws" {
  region = "us-west-2"
}

resource "aws_security_group" "airbyte_rds_sg" {
  name        = "airbyte-rds-sg"
  description = "Allow inbound traffic on PostgreSQL port"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "airbyte_rds_sg_outbound" {
  name        = "airbyte-rds-sg-outbound"
  description = "Allow outbound traffic"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "airbyte_rds" {
  allocated_storage      = 5
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  name                   = "airbyte-rds"
  username               = "airbyte"
  password               = "AirbyteConnectorTest123!"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.airbyte_rds_sg.id, aws_security_group.airbyte_rds_sg_outbound.id]
}

resource "aws_subnet" "airbyte_public_subnet_1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = "vpc-12345678"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "airbyte_public_subnet_2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = "vpc-12345678"
  availability_zone = "us-west-2b"
}

resource "aws_db_instance" "airbyte_rds" {
  depends_on = [aws_subnet.airbyte_public_subnet_1, aws_subnet.airbyte_public_subnet_2]
}