resource "aws_elasticache_user" "example" {
  user_id                 = "my-user"
  engine                  = "redis"
  access_string           = "on ~* @all +@write ~* &@read"
  no_password_required    = false
  passwords               = ["my-password"]
}

resource "aws_elasticache_user_group" "example" {
  user_group_id   = "my-user-group"
  engine         = "redis"
  user_ids       = [aws_elasticache_user.example.user_id]
}