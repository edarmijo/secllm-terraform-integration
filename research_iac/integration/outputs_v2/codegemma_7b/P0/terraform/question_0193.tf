resource "aws_db_parameter_group" "db_parameter_group" {
  name = "database-call-reduction"

  parameter {
    name = "query_cache_size"
    value = "1048576"
  }

  parameter {
    name = "query_caching_size"
    value = "1048576"
  }

  parameter {
    name = "statement_timeout"
    value = "60"
  }
}

resource "aws_db_instance" "db_instance" {
  name = "database-call-reduction-instance"
  engine = "mysql"
  engine_version = "8.0.27"
  allocated_storage = 20
  instance_class = "db.t3.medium"

  parameter_group_name = aws_db_parameter_group.db_parameter_group.name
}