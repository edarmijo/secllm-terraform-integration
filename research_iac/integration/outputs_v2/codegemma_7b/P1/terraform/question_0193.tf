resource "aws_db_parameter_group" "optimized_parameters" {
  name = "optimized-parameters"

  parameter {
    name = "query_cache_size"
    value = "1048576"
  }

  parameter {
    name = "statement_timeout"
    value = "30"
  }

  parameter {
    name = "idle_session_timeout"
    value = "300"
  }
}

resource "aws_db_instance" "optimized_instance" {
  name = "optimized-instance"
  engine = "postgres"
  engine_version = "14.2"
  instance_class = "db.t3.medium"

  parameter_group_name = aws_db_parameter_group.optimized_parameters.name
}