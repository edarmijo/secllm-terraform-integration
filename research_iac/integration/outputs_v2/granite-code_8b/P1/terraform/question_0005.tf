resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_db_instance" "primary" {
  # ... other configuration options ...

  replicate_source_db = aws_db_instance.main.id
}

resource "aws_db_instance" "replica-1" {
  # ... other configuration options ...

  replicate_source_db = aws_db_instance.main.id
}

resource "aws_db_instance" "replica-2" {
  # ... other configuration options ...

  replicate_source_db = aws_db_instance.main.id
}