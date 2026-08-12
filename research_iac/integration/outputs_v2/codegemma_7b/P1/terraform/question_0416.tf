provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "db_instance" {
  engine = "postgres"
  engine_version = "14.2"
  instance_class = "db.t3.medium"
  allocated_storage = 20
  storage_type = "gp2"
  username = var.db_username
  password = var.db_password
  restore_type = "s3"
  restore_source = {
    s3_source = {
      bucket = var.s3_bucket_name
      db_file = var.s3_db_file_name
    }
  }
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_db_file_name" {
  type = string
}