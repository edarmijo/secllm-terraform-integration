resource "aws_elasticache_user" "example" {
  username = "my-redis-user"
  engine   = "redis"
}