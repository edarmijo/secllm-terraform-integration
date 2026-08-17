resource "aws_elasticache_user_group" "example" {
  engine = "memcached"
  user_ids = [
    "user1",
    "user2",
    "user3",
  ]
}