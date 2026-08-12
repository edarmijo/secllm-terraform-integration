provider "aws" {
  region = "us-east-1"
}

resource "aws_rds_cluster" "example" {
  engine                    = "aurora-mysql"
  engine_version            = "5.7.mysql_aurora.2.03.2"
  availability_zones        = ["us-east-1a", "us-east-1b"]
  database_name             = "example"
  master_username          = "admin"
  master_password          = "password"
  backup_retention_period   = 5
  preferred_backup_window  = "07:00-09:00"
  skip_final_snapshot      = true
}