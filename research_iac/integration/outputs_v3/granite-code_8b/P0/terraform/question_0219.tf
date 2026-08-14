provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "mysql" {
  identifier           = "my-mysql-instance"
  engine               = "mysql"
  engine_version       = "5.7.21"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "password"
  name                 = "my-mysql-database"
  skip_final_snapshot  = true
  storage_type         = "gp2"
  multi_az             = false
  backup_Retention_period = 7

  tags = {
    Environment = "dev"
  }
}