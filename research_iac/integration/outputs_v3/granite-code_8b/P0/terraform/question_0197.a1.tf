resource "aws_elasticache_user_group" "example" {
  user_group_id = "example-user-group"
  engine        = "redis"
  user_ids      = ["user1", "user2", "user3"]
}