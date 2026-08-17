provider "aws" {
  region = "us-east-1"
}

resource "aws_elasticache_user_group" "example" {
  name = "example_user_group"
  engine = "redis" # Specify the engine

  user {
    user_name = "user1"
    access_string = var.user1_access_string
  }

  user {
    user_name = "user2"
    access_string = var.user2_access_string
  }

  user {
    user_name = "user3"
    access_string = var.user3_access_string
  }
}