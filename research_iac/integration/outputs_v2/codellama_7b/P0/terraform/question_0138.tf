resource "aws_elasticache_user" "example" {
  name       = "my-user"
  engine     = "redis"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

resource "aws_elasticache_user_group" "example" {
  name       = "my-user-group"
  engine     = "redis"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

resource "aws_elasticache_user_group_membership" "example" {
  user_id    = aws_elasticache_user.example.name
  group_name = aws_elasticache_user_group.example.name
}