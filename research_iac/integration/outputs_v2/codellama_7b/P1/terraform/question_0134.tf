resource "aws_elasticache_user" "redis" {
  engine        = "redis"
  name          = "my-redis-user"
  access_string = "my-redis-password"
}