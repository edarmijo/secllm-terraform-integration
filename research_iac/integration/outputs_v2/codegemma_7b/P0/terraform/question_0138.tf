provider "aws" {
  region = "us-east-1"
}

resource "aws_elasticache_user" "example_user" {
  user_name = "my_elasticache_user"
  access_string = "my_access_string"
}

resource "aws_elasticache_user_group" "example_user_group" {
  user_group_name = "my_user_group"
  user_names = [aws_elasticache_user.example_user.user_name]
}