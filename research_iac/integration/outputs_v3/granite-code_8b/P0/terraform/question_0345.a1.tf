provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "mysql" {
  identifier           = "mysql-instance"
  engine               = "mysql"
  engine_version       = "5.7.21"
  instance_class       = "db.t2.small"
  username             = "admin"
  password             = "generated_password"
  skip_final_snapshot  = false
  storage_type         = "gp2"
  backup_retention_period = 7
  multi_az             = true
  security_groups      = [aws_security_group.mysql.id]

  tags = {
    Environment = "production"
  }
}

resource "aws_security_group" "mysql" {
  name_prefix = "mysql-sg"
  description = "MySQL Security Group"
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
    Environment = "production"
  }
}

resource "random_password" "mysql_password" {
  length  = 16
  special = false
}