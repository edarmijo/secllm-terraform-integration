resource "aws_elasticache_user" "example" {
  user_id       = "existing-user"
  engine        = "memcached"
  access_string = "on ~* @all +@write ~* &@all"
}

resource "aws_elasticache_user_group" "example" {
  user_group_id = "existing-user-group"
  engine        = "memcached"
  user_ids      = ["existing-user"]
}