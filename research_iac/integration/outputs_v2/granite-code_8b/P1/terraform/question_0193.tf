resource "aws_db_instance" "example" {
  identifier = "my-db-instance"
  engine     = "mysql"

  # Reduce the number of database calls by using a connection pool
  connection_pooling = true
}