resource "aws_elasticache_user" "example" {
  name     = "my-user"
  engine   = "redis"
  password = var.password
}

resource "aws_iam_group" "example" {
  name = "my-group"
}

resource "aws_iam_group_membership" "example" {
  group = aws_iam_group.example.name
  users = [aws_elasticache_user.example.name]
}