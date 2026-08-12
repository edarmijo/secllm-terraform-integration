provider "aws" {
  region = "us-east-1"
}

resource "aws_elasticache_user" "redis_user" {
  user_name = "redis_user"
  access_string = "read_only"

  authentication_mode {
    type = "password"
    password = var.redis_password
  }
}