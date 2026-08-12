resource "aws_db_instance" "webapp_rds" {
  engine               = "mysql"
  allocated_storage    = 10
  instance_class       = "db.t2.micro"
  identifier           = "mydb"
  username             = "root"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}