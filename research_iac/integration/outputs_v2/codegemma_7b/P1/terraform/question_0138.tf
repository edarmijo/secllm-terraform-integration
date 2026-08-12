resource "aws_elasticache_user_group_membership" "example" {
  user_group_name = aws_elasticache_user_group.example.name
  user_name       = aws_elasticache_user.example.user_name
}