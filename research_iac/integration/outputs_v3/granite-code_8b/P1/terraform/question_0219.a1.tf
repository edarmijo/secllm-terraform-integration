resource "aws_db_instance" "mysql" {
  identifier           = "my-mysql-instance"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.small"
  username             = var.mysql_username
  password             = var.mysql_password
  name                 = "my-mysql-database"
  skip_final_snapshot  = true
  storage_type         = "gp2"
  multi_az             = false
  backup_retention_period = 7

  # Set up the security group rules to allow traffic from specific CIDR blocks
  security_group_ids = [
    aws_security_group.mysql.id,
  ]

  # Use a valid and secure subnet group
  subnet_group = "my-subnet-group"
}