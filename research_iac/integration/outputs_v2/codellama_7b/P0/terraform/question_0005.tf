resource "aws_route53_record" "weighted_routing_policy" {
  name    = "main"
  type    = "A"
  ttl     = 60
  records = ["primary"]
}

resource "aws_db_instance" "primary" {
  identifier = "primary"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica-1" {
  identifier = "replica-1"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica-2" {
  identifier = "replica-2"
  allocated_storage    = 10
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_route53_record" "weighted_routing_policy" {
  name    = "main"
  type    = "A"
  ttl     = 60
  records = ["primary", "replica-1", "replica-2"]
}