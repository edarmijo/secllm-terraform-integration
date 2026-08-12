resource "aws_db_instance" "example" {
  identifier           = "example-db"
  engine               = "mysql"
  instance_class       = "db.t2.small"
  storage_type         = "io1"
  iops                 = 1000
  allocated_storage    = 20
  multi_az             = false
  username             = "foo"
  password             = "bar"
  character_set_name   = "utf8"
  skip_final_snapshot  = true
  backup_Retention_period = 7

  tags = {
    Environment = "dev"
  }
}