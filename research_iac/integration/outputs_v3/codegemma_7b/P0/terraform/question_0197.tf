provider "aws" {
  region = "us-east-1"
}

resource "aws_elasticache_user_group" "example" {
  name = "my_user_group"

  user_count = 3

  user {
    user_name = "user1"
  }

  user {
    user_name = "user2"
  }

  user {
    user_name = "user3"
  }
}