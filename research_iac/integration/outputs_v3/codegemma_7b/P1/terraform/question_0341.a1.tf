resource "aws_rds_instance" "database" {
  engine = "postgres"
  engine_version = "15.3"
  allocated_storage = 20
  instance_class = "db.t3.medium"
  publicly_accessible = true

  vpc_security_group_ids = [aws_security_group.database_access.id]

  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "database"
  }
}