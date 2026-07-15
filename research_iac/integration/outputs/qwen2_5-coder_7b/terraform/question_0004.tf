provider "aws" {
  region = "us-west-2"
}

resource "aws_db_instance" "internal" {
  identifier             = "internal-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "password123"
  allocated_storage      = 20
  vpc_security_group_ids = [aws_security_group.internal.id]
  subnet_group_name        = aws_db_subnet_group.main.name
}

resource "aws_db_instance" "public" {
  identifier             = "public-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "password123"
  allocated_storage      = 20
  vpc_security_group_ids = [aws_security_group.public.id]
  subnet_group_name        = aws_db_subnet_group.main.name
}

resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]
}

resource "aws_route53_zone" "private" {
  name = "internal.example.com"
}

resource "aws_route53_zone" "public" {
  name = "external.example.com"
}

resource "aws_route53_record" "internal_db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.internal.example.com"
  type    = "A"
  ttl     = 300
  records = [aws_db_instance.internal.endpoint]
}

resource "aws_route53_record" "public_db" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "db.external.example.com"
  type    = "A"
  ttl     = 300
  records = [aws_db_instance.public.endpoint]
}

resource "aws_security_group" "internal" {
  name        = "internal-db-sg"
  description = "Security group for internal database"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public" {
  name        = "public-db-sg"
  description = "Security group for public database"

  ingress {
    from_port   = 3306
    to_port     = 3306
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

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}