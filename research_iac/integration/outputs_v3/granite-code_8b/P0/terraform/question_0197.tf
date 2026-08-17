resource "aws_elasticache_user_group" "example" {
  name = "example-user-group"
  user_ids = [
    "user1",
    "user2",
    "user3",
  ]
}