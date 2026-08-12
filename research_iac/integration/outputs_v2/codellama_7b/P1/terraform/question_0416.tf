provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine               = "mysql"
  allocated_storage    = 20
  instance_class       = "db.t3.micro"
  name                 = "example"
  username             = var.username
  password             = var.password
  skip_final_snapshot  = true
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
  acl    = "private"
}

resource "aws_s3_bucket_object" "example" {
  bucket       = aws_s3_bucket.example.id
  key          = "example/database.sql"
  source       = "/path/to/database.sql"
  content_type = "application/octet-stream"
}

resource "aws_db_instance" "restored" {
  engine               = aws_db_instance.example.engine
  allocated_storage    = aws_db_instance.example.allocated_storage
  instance_class       = aws_db_instance.example.instance_class
  name                 = "restored-database"
  username             = var.username
  password             = var.password
  skip_final_snapshot  = true
}

resource "aws_db_instance" "restored" {
  engine               = aws_db_instance.example.engine
  allocated_storage    = aws_db_instance.example.allocated_storage
  instance_class       = aws_db_instance.example.instance_class
  name                 = "restored-database"
  username             = var.username
  password             = var.password
  skip_final_snapshot  = true
}