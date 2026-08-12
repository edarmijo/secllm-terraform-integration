resource "aws_rds_db_instance" "web_app_db_instance" {
  db_name = "web_app_db"
  engine = "mysql"
  allocated_storage = 20
  instance_class = "db.t2.micro"
  username = "web_app_user"
  password = var.web_app_db_password
  vpc_security_group_ids = [aws_security_group.web_app_security_group.id]

  # Add the following line to specify the RDS instance identifier
  identifier = "web_app_db_instance"
}