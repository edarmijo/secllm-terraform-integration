resource "aws_elasticache_user_group" "example" {
  name        = "example-user-group"
  engine      = "redis"
  description = "Example user group for ElastiCache"

  user {
    username = "user1"
    password = var.user1_password
  }

  user {
    username = "user2"
    password = var.user2_password
  }

  user {
    username = "user3"
    password = var.user3_password
  }
}