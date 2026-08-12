# Create a PostgreSQL database instance in AWS
resource "aws_db_instance" "example" {
  engine           = "postgres"
  engine_version    = "12.7"
  instance_class   = "db.t3.small"
  storage_type     = "gp2"
  allocated_storage = 5

  # Set up the VPC and subnets
 vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id               = aws_subnet.example.id

  # Set the maintenance window
  maintenance_window = "mon:00:00-mon:03:00"
}