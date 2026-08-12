resource "aws_db_instance" "example" {
  identifier           = "example-db"
  engine               = "mysql"
  engine_version       = "5.7.21"
  instance_class       = "db.t2.small"
  storage_type         = "io1"
  iops                 = 1000
  multi_az             = true
  backup_Retention_period = 7
  character_set_name   = "utf8mb4"

  username = "exampleuser"
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.example.name
  security_group_ids    = [aws_security_group.example.id]
  parameter_group_name  = aws_db_parameter_group.example.name
}