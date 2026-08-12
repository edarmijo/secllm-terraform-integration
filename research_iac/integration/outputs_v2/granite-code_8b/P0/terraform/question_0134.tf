resource "aws_elasticache_user" "example" {
  engine = "redis"
  user_id = "my-user"
  access_string = "on ~* @all +@write ~* &*"
}