resource "aws_elasticache_user" "example" {
  engine = "redis"

  username = "my-username"
  password = "my-password"

  access_string = "on ~* @all +@write ~* &*"
}