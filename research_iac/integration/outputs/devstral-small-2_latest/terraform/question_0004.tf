provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "private" {
  name = "internal.example.com"
}

resource "aws_route53_zone" "public" {
  name = "external.example.com"
}

resource "aws_db_instance" "internal" {
  identifier             = "internal-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "password123"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.internal.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}

resource "aws_db_instance" "public" {
  identifier             = "public-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "password123"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.public.id]
  skip_final_snapshot    = true
  publicly_accessible    = true
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_route53_record" "internal_db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.internal.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.internal.endpoint]
}

resource "aws_route53_record" "public_db" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "db.external.example.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.public.endpoint]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "internal" {
  name   = "internal-db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "public" {
  name   = "public-db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}