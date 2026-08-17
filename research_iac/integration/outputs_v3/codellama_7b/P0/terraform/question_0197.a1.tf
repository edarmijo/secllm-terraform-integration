resource "aws_elasticache_user_group" "example" {
  engine        = "redis"
  user_group_id = "example-user-group"
  users = [
    {
      user_id = "user1"
      password = "password1"
    },
    {
      user_id = "user2"
      password = "password2"
    },
    {
      user_id = "user3"
      password = "password3"
    }
  ]
}