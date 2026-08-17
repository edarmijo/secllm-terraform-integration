# Create an AWS mySQL instance
resource "aws_db_instance" "mysql" {
  engine           = "mysql"
  engine_version   = "5.7"
  instance_class   = "db.t2.small"
  identifier       = "my-mysql-instance"
  username         = "myuser"
  password         = "mypassword"
  storage_type     = "gp2"
  multi_az         = true
  backup_Retention_period = 7
  skip_final_snapshot = true
  parameter_group_name = "default.mysql5.7"
  security_groups = [
    aws_security_group.mysql.id,
  ]
  tags = {
    Name = "my-mysql-instance"
  }
}

# Create a snapshot of the mySQL instance
resource "aws_db_snapshot" "mysql_snapshot" {
  db_instance_identifier = aws_db_instance.mysql.id
  db_snapshot_identifier  = "my-mysql-snapshot"
}