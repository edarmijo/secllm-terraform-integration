provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine               = "mysql"
  engine_version       = "8.0.21"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  name                 = "example"
  username             = "example"
  password             = var.password
  skip_final_snapshot  = false
  vpc_security_group_ids = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Allow inbound traffic"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "password" {
  type        = string
  description = "The password for the MySQL database"
}