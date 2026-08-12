provider "aws" {
  region = var.region
}

resource "aws_db_instance" "example" {
  identifier           = var.identifier
  engine               = var.engine
  instance_class       = var.instance_class
  storage_type         = var.storage_type
  allocated_storage    = var.allocated_storage
  backup_Retention_period = var.backup_retention_period

  restore_from_s3_bucket_name = var.restore_from_s3_bucket_name
  restore_from_s3_object_key  = var.restore_from_s3_object_key
}