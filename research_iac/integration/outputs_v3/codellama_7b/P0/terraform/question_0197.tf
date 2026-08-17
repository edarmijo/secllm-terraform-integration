resource "aws_elasticache_user_group" "example" {
  name        = "example-user-group"
  engine_type = "redis"
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