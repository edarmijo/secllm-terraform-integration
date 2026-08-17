provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  name                 = "example_database"
  username             = "example_user"
  password             = "example_password"
  publicly_accessible  = true
  skip_final_snapshot  = false
}

resource "aws_security_group" "example" {
  name        = "example_security_group"
  description = "Allow inbound traffic"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "example" {
  name       = "example_subnet_group"
  subnet_ids = ["subnet-12345678"]
}