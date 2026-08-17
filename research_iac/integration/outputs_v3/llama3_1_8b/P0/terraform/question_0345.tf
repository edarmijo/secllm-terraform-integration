provider "aws" {
  region = "us-west-2"
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Allow inbound traffic on port 3306"

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

  tags = {
    Name = "mysql-sg"
  }
}

resource "aws_db_instance" "mysql_instance" {
  identifier           = "mysql-instance"
  instance_class       = "db.t2.micro"
  engine               = "mysql"
  engine_version       = "5.7.22"
  username             = "admin"
  password             = random_string.mysql_password.result
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  publicly_accessible  = true
  skip_final_snapshot  = false
}

resource "random_string" "mysql_password" {
  length  = 16
  special = true
  upper   = false
}