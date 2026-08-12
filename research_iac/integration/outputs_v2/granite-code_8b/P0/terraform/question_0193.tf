resource "aws_db_instance" "example" {
  identifier = "example-db"
  engine     = "mysql"

  # Other configuration options...

  # Use a data source to retrieve the latest version of the MySQL engine
  # This will reduce the number of database calls and ensure that you are using the most up-to-date version
  engine_version = data.aws_db_engine_version.latest.version
}